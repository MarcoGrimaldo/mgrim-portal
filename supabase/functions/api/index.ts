// Public, read-only REST gateway for the portfolio content.
//
//   GET /api/resume          everything below in one response
//   GET /api/profile
//   GET /api/social-links
//   GET /api/skills
//   GET /api/work
//   GET /api/education
//   GET /api/projects
//   GET /api/hackathons
//   GET /api/euler-problems
//
// Reads go through the anon role, so row level security still applies.

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

  hackathons: async (db) => {
    const { data } = await db
      .from("hackathons")
      .select("title, dates, description, image, links")
      .order("sort_order")
      .throwOnError();
    return data;
  },

  "euler-problems": async (db) => {
    const { data } = await db
      .from("euler_problems")
      .select("title, description, link")
      .order("sort_order")
      .throwOnError();
    return data;
  },
};

async function resume(db: Db) {
  const [profile, socialLinks, skills, work, education, projects, hackathons, eulerProblems] =
    await Promise.all([
      resources.profile(db),
      resources["social-links"](db),
      resources.skills(db),
      resources.work(db),
      resources.education(db),
      resources.projects(db),
      resources.hackathons(db),
      resources["euler-problems"](db),
    ]);
  return { profile, socialLinks, skills, work, education, projects, hackathons, eulerProblems };
}

function json(body: unknown, status = 200, headers: Record<string, string> = {}) {
  return Response.json(body, { status, headers });
}

export default {
  fetch: withSupabase({ auth: "none" }, async (req, ctx) => {
    if (req.method !== "GET") {
      return json({ error: "Method not allowed" }, 405, { Allow: "GET" });
    }

    // The path arrives as /api/<resource>, with or without the /functions/v1 prefix.
    const resource = new URL(req.url).pathname
      .replace(/^(\/functions\/v1)?\/api\/?/, "")
      .replace(/\/$/, "");

    const load = resource === "resume" ? resume : resources[resource];
    if (!load) {
      return json({ error: `Unknown resource "${resource}"` }, 404);
    }

    try {
      return json(await load(ctx.supabase), 200, {
        "Cache-Control": "public, max-age=60",
      });
    } catch (error) {
      console.error(error);
      return json({ error: "Failed to load content" }, 500);
    }
  }),
};
