# mgrim-portal

Backend for [mgrim.dev](https://mgrim.dev). Everything here runs on Supabase; the UI lives in the separate `mgrim` repo and is deployed on Vercel.

## What is in here

- `supabase/migrations/` — database schema and initial content (profile, social links, skills, work, education, projects), plus the blog's `posts` and `admins` tables. The resume tables are publicly readable and writable only from the Supabase dashboard or with the secret key; posts are written through the API by users listed in `admins`.
- `supabase/config.toml` — local stack configuration.
- `supabase/functions/api/` — the REST API the UI consumes (a Supabase Edge Function): public reads, plus sign-in and post management for the blog's author.
- `.github/workflows/deploy.yml` — applies migrations and deploys the function on push.

## REST API

Base URL: `https://<project-ref>.supabase.co/functions/v1/api` (locally `http://127.0.0.1:54321/functions/v1/api`).

Public, no key needed:

| Endpoint                 | Returns                                   |
| ------------------------ | ----------------------------------------- |
| `GET /resume`            | everything in the six rows below, in one response |
| `GET /profile`           | name, description, summary, avatar, contact |
| `GET /social-links`      | links shown in the navbar                 |
| `GET /skills`            | `{ dev: [], tools: [] }`                  |
| `GET /work`              | work experience                           |
| `GET /education`         | education                                 |
| `GET /projects`          | projects                                  |
| `GET /posts`             | published blog posts, newest first (`?tag=`, `?limit=`) |
| `GET /posts/:slug`       | one published post with its Markdown content |
| `POST /posts/:slug/view` | counts a visit                            |
| `POST /auth/login`       | `{ email, password }` → access and refresh tokens |
| `POST /auth/refresh`     | `{ refreshToken }` → a new session        |

With `Authorization: Bearer <accessToken>` of a user listed in `admins`:

| Endpoint                  | Does                          |
| ------------------------- | ----------------------------- |
| `GET /admin/posts`        | every post, any status        |
| `POST /admin/posts`       | creates a post                |
| `GET /admin/posts/:id`    | one post with its content     |
| `PATCH /admin/posts/:id`  | updates a post                |
| `DELETE /admin/posts/:id` | deletes a post                |

Icons are returned as keys (`"globe"`, `"github"`); the UI maps them to components.

## Blog access

A post is a `draft`, `published` or `unpublished`; only published posts are public. To let someone manage posts from the site's `/admin` dashboard, in each Supabase project:

1. Authentication → Users → Add user (email and password).
2. SQL editor: `insert into public.admins (user_id) select id from auth.users where email = '<email>';`

## Local development

Needs Docker and pnpm.

```bash
pnpm install
pnpm start        # start a local Supabase stack with all migrations applied
pnpm db:reset     # rebuild the local database from the migrations
pnpm stop
```

## Changing the schema

```bash
pnpm exec supabase migration new <name>   # creates the migration file
pnpm db:reset                             # test it locally
pnpm db:types                             # regenerate database.types.ts for consumers
```

## Environments

| Branch    | GitHub environment | Supabase project |
| --------- | ------------------ | ---------------- |
| `main`    | `production`       | production       |
| `staging` | `staging`          | staging          |

The workflow needs a repository secret `SUPABASE_ACCESS_TOKEN` (a scoped personal access token), and in each GitHub environment the secrets `SUPABASE_PROJECT_REF` and `SUPABASE_DB_PASSWORD`.

To apply migrations by hand:

```bash
pnpm exec supabase login
pnpm exec supabase link --project-ref <ref>
pnpm db:push
pnpm exec supabase functions deploy api
```
