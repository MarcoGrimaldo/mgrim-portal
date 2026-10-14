// REST gateway for the portfolio content and the blog.
//
// Public, no credentials:
//   GET  /api/resume              profile, social links, skills, work, education, projects
//   GET  /api/profile | social-links | skills | work | education | projects
//   GET  /api/posts               published posts, newest first (?tag=, ?limit=)
//   GET  /api/posts/:slug         one published post with its content
//   POST /api/posts/:slug/view    counts a visit
//   POST /api/auth/login          { email, password } -> session (admins only)
//   POST /api/auth/refresh        { refreshToken } -> session
//
// Admin, "Authorization: Bearer <accessToken>" of a user listed in public.admins:
//   GET    /api/admin/posts       every post, any status
//   POST   /api/admin/posts
//   GET    /api/admin/posts/:id
//   PATCH  /api/admin/posts/:id
//   DELETE /api/admin/posts/:id
//
// Reads and writes go through the caller's role (anon or the signed-in user), so
// row level security still applies.

import "@supabase/functions-js/edge-runtime.d.ts";
import { type SupabaseContext, withSupabase } from "@supabase/server";

type Db = SupabaseContext["supabase"];

const resources: Record<string, (db: Db) => Promise<unknown>> = {
  profile: async (db) => {
    const { data } = await db.from("profile").select("*").single().throwOnError();
    return {
      name: data.name,
      initials: data.initials,
      url: data.url,
      location: data.location,
      locationLink: data.location_link,
      description: data.description,
      summary: data.summary,
      avatarUrl: data.avatar_url,
      email: data.email,
      tel: data.tel,
    };
  },

  "social-links": async (db) => {
    const { data } = await db
      .from("social_links")
      .select("name, url, icon, navbar")
      .order("sort_order")
      .throwOnError();
    return data;
  },

  skills: async (db) => {
    const { data } = await db
      .from("skills")
      .select("name, category")
      .order("sort_order")
      .throwOnError();
    const names = (category: string) =>
      data.filter((s) => s.category === category).map((s) => s.name);
    return { dev: names("dev"), tools: names("tools") };
  },

  work: async (db) => {
    const { data } = await db.from("work").select("*").order("sort_order").throwOnError();
    return data.map((w) => ({
      company: w.company,
      href: w.href,
      badges: w.badges,
      location: w.location,
      title: w.title,
      logoUrl: w.logo_url,
      start: w.period_start,
      end: w.period_end,
      description: w.description,
    }));
  },

  education: async (db) => {
    const { data } = await db.from("education").select("*").order("sort_order").throwOnError();
    return data.map((e) => ({
      school: e.school,
      href: e.href,
      degree: e.degree,
      logoUrl: e.logo_url,
      start: e.period_start,
      end: e.period_end,
    }));
  },

  projects: async (db) => {
    const { data } = await db
      .from("projects")
      .select("title, href, dates, active, description, technologies, links, image, video")
      .order("sort_order")
      .throwOnError();
    return data;
  },
};

async function resume(db: Db) {
  const [profile, socialLinks, skills, work, education, projects] = await Promise.all([
    resources.profile(db),
    resources["social-links"](db),
    resources.skills(db),
    resources.work(db),
    resources.education(db),
    resources.projects(db),
  ]);
  return { profile, socialLinks, skills, work, education, projects };
}

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function json(body: unknown, status = 200, headers: Record<string, string> = {}) {
  return Response.json(body, { status, headers: { "Cache-Control": "no-store", ...headers } });
}

const PUBLIC_CACHE = { "Cache-Control": "public, max-age=60" };

async function readBody(req: Request): Promise<Record<string, unknown>> {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new HttpError(400, "Expected a JSON object");
  }
  return body;
}

// ---------------------------------------------------------------- posts

const POST_STATUSES = ["draft", "published", "unpublished"];
const SLUG_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const SUMMARY_COLUMNS = "slug, title, excerpt, cover_image, tags, featured, published_at, reading_minutes";
const ADMIN_COLUMNS = `id, status, views, created_at, updated_at, ${SUMMARY_COLUMNS}`;

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

const toSummary = (p: Row) => ({
  slug: p.slug,
  title: p.title,
  excerpt: p.excerpt,
  coverImage: p.cover_image,
  tags: p.tags,
  featured: p.featured,
  publishedAt: p.published_at,
  readingMinutes: p.reading_minutes,
});

const toAdminPost = (p: Row) => ({
  ...toSummary(p),
  id: p.id,
  status: p.status,
  views: p.views,
  createdAt: p.created_at,
  updatedAt: p.updated_at,
  ...(p.content === undefined ? {} : { content: p.content }),
});

function slugify(text: string) {
  return text
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

async function listPosts(db: Db, params: URLSearchParams) {
  let query = db
    .from("posts")
    .select(SUMMARY_COLUMNS)
    .eq("status", "published")
    .order("published_at", { ascending: false });

  const tag = params.get("tag");
  if (tag) query = query.contains("tags", [tag]);

  const limit = Number(params.get("limit"));
  if (Number.isInteger(limit) && limit > 0) query = query.limit(Math.min(limit, 100));

  const { data } = await query.throwOnError();
  return data.map(toSummary);
}

async function getPost(db: Db, slug: string) {
  const { data } = await db
    .from("posts")
    .select(`${SUMMARY_COLUMNS}, content, updated_at`)
    .eq("status", "published")
    .eq("slug", slug)
    .maybeSingle()
    .throwOnError();
  if (!data) throw new HttpError(404, "Post not found");
  return { ...toSummary(data), content: data.content, updatedAt: data.updated_at };
}

// Validates the writable fields of a post and maps them to columns.
function postColumns(body: Record<string, unknown>, creating: boolean) {
  const columns: Row = {};
  const text = (key: string, max: number) => {
    const value = body[key];
    if (typeof value !== "string" || value.length > max) {
      throw new HttpError(400, `"${key}" must be a string of at most ${max} characters`);
    }
    return value;
  };

  if (creating || "title" in body) {
    columns.title = text("title", 200).trim();
    if (!columns.title) throw new HttpError(400, "A title is required");
  }
  if ("slug" in body && body.slug !== "") {
    columns.slug = text("slug", 120);
  } else if (creating) {
    columns.slug = slugify(columns.title);
  }
  if ("slug" in columns && !SLUG_PATTERN.test(columns.slug)) {
    throw new HttpError(400, "The slug may only contain lowercase letters, numbers and dashes");
  }
  if ("excerpt" in body) columns.excerpt = text("excerpt", 500).trim();
  if ("content" in body) columns.content = text("content", 200_000);
  if ("coverImage" in body) {
    columns.cover_image = text("coverImage", 2000).trim();
    if (columns.cover_image && !/^(https?:\/\/|\/)/.test(columns.cover_image)) {
      throw new HttpError(400, "The cover image must be an http(s) URL or a path starting with /");
    }
  }
  if ("tags" in body) {
    const tags = body.tags;
    if (!Array.isArray(tags) || tags.some((t) => typeof t !== "string")) {
      throw new HttpError(400, '"tags" must be a list of strings');
    }
    columns.tags = [...new Set(tags.map((t) => t.trim().toLowerCase()).filter(Boolean))].slice(0, 10);
  }
  if ("status" in body) {
    if (!POST_STATUSES.includes(body.status as string)) {
      throw new HttpError(400, `"status" must be one of ${POST_STATUSES.join(", ")}`);
    }
    columns.status = body.status;
  }
  if ("featured" in body) {
    if (typeof body.featured !== "boolean") throw new HttpError(400, '"featured" must be a boolean');
    columns.featured = body.featured;
  }
  return columns;
}

async function requireAdmin(ctx: SupabaseContext) {
  if (ctx.authMode !== "user" || !ctx.userClaims) throw new HttpError(401, "Sign in required");
  // Row level security only returns the caller's own row.
  const { data } = await ctx.supabase.from("admins").select("user_id").maybeSingle().throwOnError();
  if (!data) throw new HttpError(403, "This account cannot manage the blog");
}

async function adminPosts(req: Request, ctx: SupabaseContext, id: string | undefined) {
  await requireAdmin(ctx);
  const db = ctx.supabase;

  if (id === undefined) {
    if (req.method === "GET") {
      const { data } = await db
        .from("posts")
        .select(ADMIN_COLUMNS)
        .order("updated_at", { ascending: false })
        .throwOnError();
      return json(data.map(toAdminPost));
    }
    if (req.method === "POST") {
      const { data } = await db
        .from("posts")
        .insert(postColumns(await readBody(req), true))
        .select()
        .single()
        .throwOnError();
      return json(toAdminPost(data), 201);
    }
    throw new HttpError(405, "Method not allowed");
  }

  if (!/^\d+$/.test(id)) throw new HttpError(404, "Post not found");

  let result;
  if (req.method === "GET") {
    result = await db.from("posts").select().eq("id", id).maybeSingle().throwOnError();
  } else if (req.method === "PATCH") {
    const columns = postColumns(await readBody(req), false);
    if (Object.keys(columns).length === 0) throw new HttpError(400, "Nothing to update");
    result = await db.from("posts").update(columns).eq("id", id).select().maybeSingle().throwOnError();
  } else if (req.method === "DELETE") {
    result = await db.from("posts").delete().eq("id", id).select("id").maybeSingle().throwOnError();
    if (result.data) return json({ id: result.data.id });
  } else {
    throw new HttpError(405, "Method not allowed");
  }
  if (!result.data) throw new HttpError(404, "Post not found");
  return json(toAdminPost(result.data));
}

// ---------------------------------------------------------------- auth

type AuthResult = Awaited<ReturnType<Db["auth"]["refreshSession"]>>;

function toSession({ data, error }: AuthResult, failure: string) {
  if (error || !data.session || !data.user) throw new HttpError(401, failure);
  return {
    accessToken: data.session.access_token,
    refreshToken: data.session.refresh_token,
    expiresAt: data.session.expires_at,
    email: data.user.email,
  };
}

async function auth(req: Request, ctx: SupabaseContext, action: string | undefined) {
  if (req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const body = await readBody(req);

  if (action === "login") {
    const { email, password } = body;
    if (typeof email !== "string" || typeof password !== "string") {
      throw new HttpError(400, "Email and password are required");
    }
    const result = await ctx.supabase.auth.signInWithPassword({ email, password });
    const session = toSession(result, "Invalid email or password");
    const { data: admin } = await ctx.supabaseAdmin
      .from("admins")
      .select("user_id")
      .eq("user_id", result.data.user?.id)
      .maybeSingle()
      .throwOnError();
    if (!admin) throw new HttpError(403, "This account cannot manage the blog");
    return json(session);
  }

  if (action === "refresh") {
    if (typeof body.refreshToken !== "string") throw new HttpError(400, "refreshToken is required");
    const result = await ctx.supabase.auth.refreshSession({ refresh_token: body.refreshToken });
    return json(toSession(result, "Session expired"));
  }

  throw new HttpError(404, "Unknown auth action");
}

// ---------------------------------------------------------------- router

async function route(req: Request, ctx: SupabaseContext) {
  const url = new URL(req.url);
  // The path arrives as /api/<resource>, with or without the /functions/v1 prefix.
  const [resource, second, third, ...rest] = url.pathname
    .replace(/^(\/functions\/v1)?\/api\/?/, "")
    .split("/")
    .filter(Boolean)
    .map(decodeURIComponent);
  if (rest.length > 0) throw new HttpError(404, "Not found");

  if (resource === "auth" && third === undefined) return auth(req, ctx, second);
  if (resource === "admin" && second === "posts") return adminPosts(req, ctx, third);

  if (resource === "posts" && second !== undefined && third === "view") {
    if (req.method !== "POST") throw new HttpError(405, "Method not allowed");
    await ctx.supabaseAdmin.rpc("increment_post_views", { post_slug: second }).throwOnError();
    return json({ ok: true });
  }

  if (req.method !== "GET") throw new HttpError(405, "Method not allowed");

  if (resource === "posts" && third === undefined) {
    const body = second === undefined
      ? await listPosts(ctx.supabase, url.searchParams)
      : await getPost(ctx.supabase, second);
    return json(body, 200, PUBLIC_CACHE);
  }

  const load = resource === "resume" ? resume : resources[resource ?? ""];
  if (!load || second !== undefined) {
    throw new HttpError(404, `Unknown resource "${url.pathname}"`);
  }
  return json(await load(ctx.supabase), 200, PUBLIC_CACHE);
}

export default {
  // A request without credentials is anonymous; one with an invalid token is rejected.
  fetch: withSupabase({ auth: ["user", "none"] }, async (req, ctx) => {
    try {
      return await route(req, ctx);
    } catch (error) {
      if (error instanceof HttpError) return json({ error: error.message }, error.status);
      if ((error as { code?: string }).code === "23505") {
        return json({ error: "Another post already uses that slug" }, 409);
      }
      console.error(error);
      return json({ error: "Something went wrong" }, 500);
    }
  }),
};
