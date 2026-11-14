-- Casa das Estrelas: video support for Highlights
alter table public.posts add column if not exists video_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'highlight-videos',
  'highlight-videos',
  true,
  104857600,
  array['video/mp4','video/webm','video/quicktime']
)
on conflict (id) do update
set public = true,
    file_size_limit = 104857600,
    allowed_mime_types = array['video/mp4','video/webm','video/quicktime'];

drop policy if exists "Public can view highlight videos" on storage.objects;
create policy "Public can view highlight videos"
on storage.objects for select
using (bucket_id = 'highlight-videos');

drop policy if exists "Admin uploads highlight videos" on storage.objects;
create policy "Admin uploads highlight videos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'highlight-videos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
);

drop policy if exists "Admin updates highlight videos" on storage.objects;
create policy "Admin updates highlight videos"
on storage.objects for update to authenticated
using (
  bucket_id = 'highlight-videos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
)
with check (
  bucket_id = 'highlight-videos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
);

drop policy if exists "Admin deletes highlight videos" on storage.objects;
create policy "Admin deletes highlight videos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'highlight-videos'
  and (auth.jwt() ->> 'email') = 'blackmoonplc@gmail.com'
);
