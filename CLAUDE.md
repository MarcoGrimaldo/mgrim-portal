# CLAUDE.md

Backend for Marco Grimaldo's portfolio (https://mgrim.dev). Everything runs on Supabase: a Postgres database holding the site's content and blog posts, Supabase Auth for the blog's author, and one Edge Function that serves it all as a REST API: public and read-only for the site's content, authenticated for managing posts. The UI is the separate `mgrim` repo (https://github.com/MarcoGrimaldo/mgrim, usually checked out at `../mgrim`), a Next.js app on Vercel that only calls this API, from its server.

## Commands

```bash
pnpm install
pnpm start        # supabase start: local stack (needs Docker) with all migrations applied
pnpm db:reset     # rebuild the local database from the migrations
pnpm stop
pnpm db:types     # regenerate database.types.ts from the local database
```

- The Supabase CLI is a pinned dev dependency; run it as `pnpm exec supabase ...`. Check `--help` before using a subcommand, the CLI changes between versions.
- When running CLI commands non-interactively, close stdin (`</dev/null`) and pass `--yes` where a prompt is expected. `supabase migration new <name>` waits on stdin forever otherwise.
- There are no tests. Validate by applying migrations to a local stack or to staging and calling the API with `curl`.
- `pnpm start` serves the function too, at `http://127.0.0.1:54321/functions/v1/api`. The UI can run against it: `PORTAL_API_URL=http://127.0.0.1:54321/functions/v1/api pnpm dev` in `../mgrim`.

## Layout

```
supabase/
  config.toml                 local stack config; [functions.api] has verify_jwt = false
  migrations/                 schema and content, applied in filename order
  functions/api/
    index.ts                  the REST gateway
    deno.json                 import map (@supabase/server, @supabase/functions-js)
.github/workflows/deploy.yml  applies migrations and deploys functions per branch
```

## Environments

| Git branch | GitHub environment | Supabase project ref     | API base URL                                                |
| ---------- | ------------------ | ------------------------ | ----------------------------------------------------------- |
| `main`     | `production`       | `chzulbecjriscqyitqkj`   | `https://chzulbecjriscqyitqkj.supabase.co/functions/v1/api` |
| `staging`  | `staging`          | `kwtghytfaspwuctqgixu`   | `https://kwtghytfaspwuctqgixu.supabase.co/functions/v1/api` |

- A push to `staging` or `main` that touches `supabase/**` runs `deploy.yml`: `supabase link`, `supabase db push`, `supabase functions deploy`. It can also be started by hand (`gh workflow run deploy.yml --ref <branch>`).
- Secrets: `SUPABASE_ACCESS_TOKEN` at repository level; `SUPABASE_PROJECT_REF` and `SUPABASE_DB_PASSWORD` in each GitHub environment. The environment names must be exactly `staging` and `production`.
- Flow: commit to `staging`, check the staging API, then merge `staging` into `main`. Deploy the backend before the UI change that depends on it.
- The two databases are independent. Rows edited in one project's dashboard do not reach the other; a change that belongs in both goes in a migration.
- The local checkout is linked to staging (`supabase/.temp/project-ref`). To target production from the CLI pass `--project-ref chzulbecjriscqyitqkj` explicitly; with a logged-in CLI this works without the database password.

## Database

All tables are in `public` with row level security on. The resume tables are readable by everyone and writable only from the dashboard or with the secret key: each has a `"Public read"` select policy for `anon` and `authenticated`, and those roles are granted `select` only. A new table needs all three (RLS, policy, explicit grant) or the API cannot read it.

| Table            | Holds                                                                  |
| ---------------- | ---------------------------------------------------------------------- |
| `profile`        | single row (boolean primary key): name, description, summary, contact  |
| `social_links`   | dock links; `icon` is a key of the UI's `Icons` map                    |
| `skills`         | `category` is `dev` or `tools`                                         |
| `work`           | work experience; `period_start` / `period_end` are display text        |
| `education`      | education                                                              |
| `projects`       | `technologies text[]`, `links jsonb` (`[{type, href, icon}]`)          |
| `posts`          | blog posts: Markdown `content`, `tags text[]`, `status`, `featured`, `views` |
| `admins`         | `user_id` of the Auth users allowed to manage posts                    |

- Every resume list table has `sort_order`; the API orders by it and the UI renders in that order. To put a row first, shift the others.
- Icons are stored as string keys (`"globe"`, `"github"`, `"nextjs"`, `"linkedin"`, `"resume"`), never markup. A new key also needs an entry in `src/components/icons.tsx` in the UI repo; unknown keys render as the globe.

### Blog

- `posts.status` is the enum `post_status`: `draft` (never published), `published` (on the site), `unpublished` (taken down, kept). Everyone can read published rows; users listed in `admins` can read and write every row. Both rules are RLS policies, and the API writes as the signed-in user, so the database is what enforces them.
- `published_at` is set by the `posts_set_timestamps` trigger the first time a post is published and kept afterwards; the same trigger maintains `updated_at`. `reading_minutes` is a generated column (200 words per minute).
- `views` is incremented by `increment_post_views(slug)`, executable only by `service_role`; the API calls it with the admin client. The trigger does not fire for it, so counting views does not touch `updated_at`.
- Posts are content created in the dashboard of the site, per environment. They are not in migrations.

### Giving someone access to the blog dashboard

Per project (staging and production are independent):

1. In the Supabase dashboard, Authentication → Users → Add user, with an email and password (auto-confirm).
2. In the SQL editor: `insert into public.admins (user_id) select id from auth.users where email = '<email>';`

A user that is not in `admins` cannot sign in to the dashboard and cannot write posts, so open sign-ups are harmless to the blog. Turning them off anyway (Authentication → Sign In / Providers → "Allow new users to sign up") is recommended, since the site has no sign-up flow.

## Migrations

- Create files with `pnpm exec supabase migration new <name> </dev/null`, then write the SQL. Do not invent filenames.
- `20261013201723_remote_schema.sql` is the baseline both projects already had recorded; keep it, and keep new migrations dated after it.
- Content that should exist in every environment is a migration too (plain `insert` / `update`). There is no `seed.sql`: `db push` does not run seeds, so seed data would never reach the hosted projects.
- Never edit a migration that has been applied to staging or production; add a new one.
- Before pushing, `pnpm exec supabase db push --dry-run </dev/null` lists what would be applied. After schema changes, run `pnpm exec supabase db advisors --linked`.

## REST API

`supabase/functions/api/index.ts`, built on `withSupabase({ auth: ["user", "none"] })` from `@supabase/server`: a request without credentials is anonymous, one with a valid `Authorization: Bearer <access token>` runs as that user, and one with an invalid token is rejected with 401. `ctx.supabase` is the caller's client (anon or the user), so row level security applies to every read and write. `ctx.supabaseAdmin` is used in two places only: the admin lookup at sign-in and the view counter.

Public, no credentials. `GET` responses carry `Cache-Control: public, max-age=60`; everything else is `no-store`.

| Endpoint                  | Returns                                                     |
| ------------------------- | ----------------------------------------------------------- |
| `GET /resume`             | `{ profile, socialLinks, skills, work, education, projects }` |
| `GET /profile`            | profile fields in camelCase                                 |
| `GET /social-links`       | `[{ name, url, icon, navbar }]`                             |
| `GET /skills`             | `{ dev: [], tools: [] }`                                    |
| `GET /work`, `/education`, `/projects` | arrays in display order                        |
| `GET /posts`              | published posts without content, newest first; `?tag=`, `?limit=` |
| `GET /posts/:slug`        | one published post with `content`; 404 otherwise            |
| `POST /posts/:slug/view`  | counts a visit                                              |
| `POST /auth/login`        | `{ email, password }` → `{ accessToken, refreshToken, expiresAt, email }`; 401 on bad credentials, 403 when the user is not in `admins` |
| `POST /auth/refresh`      | `{ refreshToken }` → a new session                          |

Admin, bearer token of a user in `admins` (401 without a token, 403 for other users):

| Endpoint                    | Does                                                      |
| --------------------------- | --------------------------------------------------------- |
| `GET /admin/posts`          | every post, any status, without content, last updated first |
| `POST /admin/posts`         | creates a post; `title` is required, `slug` defaults to the slugified title, `status` to `draft` |
| `GET /admin/posts/:id`      | one post with `content`                                   |
| `PATCH /admin/posts/:id`    | updates the given fields                                  |
| `DELETE /admin/posts/:id`   | deletes the post                                          |

Writable post fields: `title`, `slug`, `excerpt`, `content`, `coverImage`, `tags`, `status`, `featured`. A slug already in use answers 409.

- The UI calls the API only from its server. The shapes it expects are the `ResumeResponse` type in `src/data/resume.tsx` and the post types in `src/data/blog.ts` of the UI repo: change both sides together, and deploy this side first.
- The function maps snake_case columns to camelCase where they differ (`logo_url` → `logoUrl`, `period_start` → `start`, `cover_image` → `coverImage`). A new column must be added to the function's `select` or mapping to appear in the API.
- To add a resume resource, add a loader to the `resources` map and include it in `resume()`.
- The function is deployed with `verify_jwt = false` (`config.toml`), because most of it is public; `withSupabase` validates the token itself.

## Troubleshooting

- `password authentication failed for user "postgres"` in the workflow: the environment's `SUPABASE_DB_PASSWORD` does not match that project's database password. After resetting the password in the Supabase dashboard, wait about three minutes before re-running; the connection pooler keeps rejecting the new password for a short while.
- A database password is per project. Resetting production's does not affect staging.
- `Requested function was not found` from the API URL: the function is not deployed to that project yet.
- Signing in to the site's dashboard answers "This account cannot manage the blog": the user exists in Auth but is not in `admins` for that project.
- To confirm the UI is calling the API, look at the `api` function's invocations in the Supabase dashboard; the calls come from Vercel, not from visitors' browsers.
