-- Casa das Estrelas: initial Supabase schema
create extension if not exists pgcrypto;

create table if not exists public.contestants (
  id uuid primary key default gen_random_uuid(),
  display_order integer not null unique,
  name text not null,
  photo_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('TOP NEWS','HIGHLIGHT','DENTRO DA CASA')),
  title text not null,
  excerpt text not null default '',
  tag text not null default 'NOVO',
  status text not null default 'Rascunho' check (status in ('Publicado','Rascunho')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  contestant_id uuid not null references public.contestants(id) on delete cascade,
  quantity integer not null check (quantity > 0),
  payment_status text not null default 'pending' check (payment_status in ('pending','paid','failed','refunded')),
  created_at timestamptz not null default now()
);

alter table public.contestants enable row level security;
alter table public.posts enable row level security;
alter table public.votes enable row level security;

drop policy if exists "Public can read contestants" on public.contestants;
create policy "Public can read contestants" on public.contestants for select using (true);
drop policy if exists "Public can read published posts" on public.posts;
create policy "Public can read published posts" on public.posts for select using (status = 'Publicado');

-- No public insert/update/delete policies are created. Admin write access must be
-- added after secure admin authentication is configured. Votes remain closed until
-- payment verification and anti-abuse controls are implemented.

insert into public.contestants (display_order, name) values
(1,'Aladdin Momad'),(2,'Sheyd Paula'),(3,'Jessica'),(4,'Igor Idelson'),(5,'Maura Melaço'),
(6,'Leonel Francisco'),(7,'Jujuba Ferraz'),(8,'Pai Aturmento'),(9,'Miss Cacau'),(10,'Fabio Dance'),
(11,'Melancia Fortunato'),(12,'Vanilson Veigas'),(13,'Barbie Luzimira'),(14,'Marlene Oi'),(15,'Passing Toloba'),
(16,'Victor Renner'),(17,'Leia It''s Love'),(18,'Duddas de Raça'),(19,'African Badoie'),(20,'Dehermes')
on conflict (display_order) do update set name = excluded.name;

insert into public.posts (type,title,excerpt,tag,status)
select 'TOP NEWS','A casa está ao rubro: acompanha tudo o que acontece','As novidades, os momentos decisivos e as conversas que estão a marcar esta edição.','DESTAQUE','Publicado'
where not exists (select 1 from public.posts);
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('contestant-photos','contestant-photos',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Public can view contestant photos" on storage.objects;
create policy "Public can view contestant photos" on storage.objects for select using (bucket_id = 'contestant-photos');
-- Upload/delete permissions intentionally omitted until admin authentication is enabled.


-- ADMIN ACCESS: restrict content management to the designated administrator.
-- Run this block after creating/verifying the admin account in Supabase Auth.
drop policy if exists "Admin manages contestants" on public.contestants;
create policy "Admin manages contestants" on public.contestants
for all to authenticated
using ((auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com')
with check ((auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com');

drop policy if exists "Admin manages posts" on public.posts;
create policy "Admin manages posts" on public.posts
for all to authenticated
using ((auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com')
with check ((auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com');

drop policy if exists "Admin uploads contestant photos" on storage.objects;
create policy "Admin uploads contestant photos" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'contestant-photos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
);

drop policy if exists "Admin updates contestant photos" on storage.objects;
create policy "Admin updates contestant photos" on storage.objects
for update to authenticated
using (
  bucket_id = 'contestant-photos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
)
with check (
  bucket_id = 'contestant-photos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
);

drop policy if exists "Admin deletes contestant photos" on storage.objects;
create policy "Admin deletes contestant photos" on storage.objects
for delete to authenticated
using (
  bucket_id = 'contestant-photos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
);
