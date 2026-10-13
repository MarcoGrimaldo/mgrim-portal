# mgrim-portal

Backend for [mgrim.dev](https://mgrim.dev). Everything here runs on Supabase; the UI lives in the separate `mgrim` repo and is deployed on Vercel.

## What is in here

- `supabase/migrations/` — database schema and initial content (profile, social links, skills, work, education, projects, hackathons, Euler problems). Every table is publicly readable and writable only from the Supabase dashboard or with the secret key.
- `supabase/config.toml` — local stack configuration.
- `supabase/functions/api/` — the public, read-only REST API the UI consumes (a Supabase Edge Function).
- `.github/workflows/deploy.yml` — applies migrations and deploys the function on push.

## REST API

Base URL: `https://<project-ref>.supabase.co/functions/v1/api` (locally `http://127.0.0.1:54321/functions/v1/api`). No key is needed; only `GET` is allowed.

| Endpoint          | Returns                                   |
| ----------------- | ----------------------------------------- |
| `/resume`         | everything below in one response          |
| `/profile`        | name, description, summary, avatar, contact |
| `/social-links`   | links shown in the navbar                 |
| `/skills`         | `{ dev: [], tools: [] }`                  |
| `/work`           | work experience                           |
| `/education`      | education                                 |
| `/projects`       | projects                                  |
| `/hackathons`     | Project Euler timeline                    |
| `/euler-problems` | notebook problem list                     |

Icons are returned as keys (`"globe"`, `"github"`); the UI maps them to components.

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
