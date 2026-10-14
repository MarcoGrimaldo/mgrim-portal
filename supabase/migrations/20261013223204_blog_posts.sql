-- Replaces the Project Euler content with a blog.
--
-- Posts are written from the site's /admin dashboard: the API signs the author in
-- with Supabase Auth and writes as that user, so row level security decides who
-- may write. Only users listed in public.admins can.

drop table public.hackathons;
drop table public.euler_problems;

-- Users allowed to manage the blog. Rows are added by hand (dashboard or SQL editor):
--   insert into public.admins (user_id) select id from auth.users where email = '...';
create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admins enable row level security;

-- A signed-in user can see whether they are an admin, nothing else.
create policy "Read own row" on public.admins
  for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.admins from anon, authenticated;
grant select on public.admins to authenticated;
-- The API looks the user up with the secret key when they sign in.
grant select on public.admins to service_role;

-- draft: never published, work in progress.
-- published: live on the site.
-- unpublished: taken down from the site, kept in the dashboard.
create type public.post_status as enum ('draft', 'published', 'unpublished');

create table public.posts (
  id bigint generated always as identity primary key,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title text not null check (title <> ''),
  excerpt text not null default '',
  -- Markdown (GFM, fenced code, $math$)
  content text not null default '',
  cover_image text not null default '',
  tags text[] not null default '{}',
  status public.post_status not null default 'draft',
  -- pinned to the top of the blog index
  featured boolean not null default false,
  views bigint not null default 0,
  reading_minutes integer not null generated always as (
    greatest(1, ceil(coalesce(array_length(regexp_split_to_array(btrim(content), '\s+'), 1), 0) / 200.0)::integer)
  ) stored,
  -- set the first time the post is published, kept afterwards
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index posts_published_at_idx on public.posts (published_at desc) where status = 'published';

create function public.posts_set_timestamps()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    new.updated_at := now();
  end if;
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

-- Not fired by view counting, which only touches "views".
create trigger posts_set_timestamps
  before insert or update of slug, title, excerpt, content, cover_image, tags, status, featured, published_at
  on public.posts
  for each row execute function public.posts_set_timestamps();

alter table public.posts enable row level security;

create policy "Public read published" on public.posts
  for select to anon, authenticated
  using (status = 'published');

create policy "Admins read all" on public.posts
  for select to authenticated
  using (exists (select 1 from public.admins where user_id = (select auth.uid())));

create policy "Admins insert" on public.posts
  for insert to authenticated
  with check (exists (select 1 from public.admins where user_id = (select auth.uid())));

create policy "Admins update" on public.posts
  for update to authenticated
  using (exists (select 1 from public.admins where user_id = (select auth.uid())))
  with check (exists (select 1 from public.admins where user_id = (select auth.uid())));

create policy "Admins delete" on public.posts
  for delete to authenticated
  using (exists (select 1 from public.admins where user_id = (select auth.uid())));

revoke all on public.posts from anon, authenticated;
grant select on public.posts to anon;
grant select, insert, update, delete on public.posts to authenticated;

-- Called by the API with the secret key when a visitor opens a post.
create function public.increment_post_views(post_slug text)
returns void
language sql
set search_path = ''
as $$
  update public.posts set views = views + 1
  where slug = post_slug and status = 'published';
$$;

revoke execute on function public.increment_post_views(text) from public, anon, authenticated;
grant execute on function public.increment_post_views(text) to service_role;
