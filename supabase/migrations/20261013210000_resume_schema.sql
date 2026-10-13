-- Resume content for the portfolio site.
-- Every table is publicly readable (anon key) and writable only from the
-- Supabase dashboard / service role. List tables use sort_order for display order.

create table public.profile (
  -- single-row table
  id boolean primary key default true check (id),
  name text not null,
  initials text not null,
  url text not null,
  location text not null,
  location_link text not null,
  description text not null,
  summary text not null,
  avatar_url text not null,
  email text not null,
  tel text not null
);

create table public.social_links (
  id bigint generated always as identity primary key,
  name text not null unique,
  url text not null,
  -- key of the Icons map in src/components/icons.tsx
  icon text not null,
  navbar boolean not null default true,
  sort_order integer not null default 0
);

create table public.skills (
  id bigint generated always as identity primary key,
  name text not null,
  category text not null check (category in ('dev', 'tools')),
  sort_order integer not null default 0,
  unique (category, name)
);

create table public.work (
  id bigint generated always as identity primary key,
  company text not null,
  href text not null,
  badges text[] not null default '{}',
  location text not null,
  title text not null,
  logo_url text not null,
  period_start text not null,
  period_end text,
  description text not null,
  sort_order integer not null default 0
);

create table public.education (
  id bigint generated always as identity primary key,
  school text not null,
  href text not null,
  degree text not null,
  logo_url text not null,
  period_start text not null,
  period_end text not null,
  sort_order integer not null default 0
);

create table public.projects (
  id bigint generated always as identity primary key,
  title text not null,
  href text not null,
  dates text not null,
  active boolean not null default true,
  description text not null,
  technologies text[] not null default '{}',
  -- [{ "type": "Website", "href": "...", "icon": "globe" }]
  links jsonb not null default '[]',
  image text not null default '',
  video text not null default '',
  sort_order integer not null default 0
);

create table public.hackathons (
  id bigint generated always as identity primary key,
  title text not null,
  dates text not null,
  description text not null,
  image text not null default '',
  -- [{ "title": "Web problem", "href": "...", "icon": "globe" }]
  links jsonb not null default '[]',
  sort_order integer not null default 0
);

create table public.euler_problems (
  id bigint generated always as identity primary key,
  title text not null,
  description text not null,
  link text not null,
  sort_order integer not null default 0
);

alter table public.profile enable row level security;
alter table public.social_links enable row level security;
alter table public.skills enable row level security;
alter table public.work enable row level security;
alter table public.education enable row level security;
alter table public.projects enable row level security;
alter table public.hackathons enable row level security;
alter table public.euler_problems enable row level security;

create policy "Public read" on public.profile for select to anon, authenticated using (true);
create policy "Public read" on public.social_links for select to anon, authenticated using (true);
create policy "Public read" on public.skills for select to anon, authenticated using (true);
create policy "Public read" on public.work for select to anon, authenticated using (true);
create policy "Public read" on public.education for select to anon, authenticated using (true);
create policy "Public read" on public.projects for select to anon, authenticated using (true);
create policy "Public read" on public.hackathons for select to anon, authenticated using (true);
create policy "Public read" on public.euler_problems for select to anon, authenticated using (true);

-- Read-only for the public API roles, regardless of the project's default grants.
revoke all on
  public.profile,
  public.social_links,
  public.skills,
  public.work,
  public.education,
  public.projects,
  public.hackathons,
  public.euler_problems
from anon, authenticated;

grant select on
  public.profile,
  public.social_links,
  public.skills,
  public.work,
  public.education,
  public.projects,
  public.hackathons,
  public.euler_problems
to anon, authenticated;
