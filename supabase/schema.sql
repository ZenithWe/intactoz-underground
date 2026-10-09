-- Execute APENAS em um projeto Supabase dedicado ao Intactoz.
-- Nunca execute nos bancos de outros sites.
-- Crie a primeira conta pela interface, confirme o e-mail e libere o admin no final.
create extension if not exists pgcrypto;

create table if not exists public.intactoz_admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.intactoz_admin_users enable row level security;
-- Sem políticas de gravação/leitura para o navegador: somente SQL administrativo pode gerenciar administradores.

create or replace function public.is_intactoz_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists(
    select 1 from public.intactoz_admin_users a
    where a.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_intactoz_admin() from public;
grant execute on function public.is_intactoz_admin() to anon, authenticated;

create table if not exists public.categories (
 name text primary key check(char_length(trim(name)) between 1 and 80),
 created_at timestamptz not null default now()
);
create table if not exists public.collections (
 name text primary key check(char_length(trim(name)) between 1 and 80),
 created_at timestamptz not null default now()
);
create table if not exists public.products (
 id text primary key,
 name text not null check(char_length(trim(name)) between 1 and 200),
 short_name text not null check(char_length(trim(short_name)) between 1 and 90),
 price_cents integer not null check(price_cents >= 0),
 category text not null,
 collection text not null,
 color text not null default 'PRETO',
 description text not null default '',
 material text not null default '',
 images text[] not null default '{}',
 url text not null default '',
 created_at timestamptz not null default now(),
 constraint intactoz_max_images check (cardinality(images) <= 12)
);

alter table public.categories enable row level security;
alter table public.collections enable row level security;
alter table public.products enable row level security;

create policy "intactoz_public_categories_read" on public.categories for select to anon, authenticated using(true);
create policy "intactoz_public_collections_read" on public.collections for select to anon, authenticated using(true);
create policy "intactoz_public_products_read" on public.products for select to anon, authenticated using(true);

create policy "intactoz_categories_admin_insert" on public.categories for insert to authenticated with check(public.is_intactoz_admin());
create policy "intactoz_categories_admin_update" on public.categories for update to authenticated using(public.is_intactoz_admin()) with check(public.is_intactoz_admin());
create policy "intactoz_categories_admin_delete" on public.categories for delete to authenticated using(public.is_intactoz_admin());
create policy "intactoz_collections_admin_insert" on public.collections for insert to authenticated with check(public.is_intactoz_admin());
create policy "intactoz_collections_admin_update" on public.collections for update to authenticated using(public.is_intactoz_admin()) with check(public.is_intactoz_admin());
create policy "intactoz_collections_admin_delete" on public.collections for delete to authenticated using(public.is_intactoz_admin());
create policy "intactoz_products_admin_insert" on public.products for insert to authenticated with check(public.is_intactoz_admin());
create policy "intactoz_products_admin_update" on public.products for update to authenticated using(public.is_intactoz_admin()) with check(public.is_intactoz_admin());
create policy "intactoz_products_admin_delete" on public.products for delete to authenticated using(public.is_intactoz_admin());

insert into public.categories(name) values ('Acessórios'),('Camisetas'),('Moletons') on conflict do nothing;
insert into public.collections(name) values ('Chroma'),('Quadro'),('Se Vc N Ama') on conflict do nothing;
insert into public.products(id,name,short_name,price_cents,category,collection,color,description,material,images,url) values
('bone','Boné Sidoka Se Vc N Ama Preto','SE VC N AMA / CAP',13990,'Acessórios','Se Vc N Ama','PRETO','Boné preto da coleção Se Vc N Ama, Sidoka e intactoz. Veja o acabamento e a disponibilidade na loja original.','Composição a confirmar',array['https://intactoz-underground.contamateusfortnite.chatgpt.site/images/bone-1.webp','https://intactoz-underground.contamateusfortnite.chatgpt.site/images/bone-2.webp'],'https://intactoz.com.br/products/bone-sidoka-se-vc-n-ama-preto'),
('chroma','Camiseta Sidoka Chroma Preta','CHROMA',14990,'Camisetas','Chroma','PRETO','Camiseta preta da linha Sidoka Chroma.','Composição a confirmar',array['https://intactoz-underground.contamateusfortnite.chatgpt.site/images/chroma-1.webp','https://intactoz-underground.contamateusfortnite.chatgpt.site/images/chroma-2.webp'],'https://intactoz.com.br/products/camiseta-sidoka-chroma-preta'),
('quadro','Moletom Canguru Preto Quadro Sidoka','QUADRO',38990,'Moletons','Quadro','PRETO','O primeiro drop desenvolvido por Sidoka para a intactoz. Modelo canguru com símbolo Futuruz refletivo.','50% algodão / 50% poliéster',array['https://intactoz.com.br/cdn/shop/files/MoletomCanguruCostas.png?v=1709910370','https://intactoz.com.br/cdn/shop/files/MoletomCanguruFrente.png?v=1709910369'],'https://intactoz.com.br/products/moletom-canguru-preto-quadro-sidoka'),
('ama','Camiseta Sidoka Se Vc N Ama Preta','SE VC N AMA',14990,'Camisetas','Se Vc N Ama','PRETO','Camiseta preta da coleção Se Vc N Ama.','Composição a confirmar',array['https://intactoz-underground.contamateusfortnite.chatgpt.site/images/ama-1.webp','https://intactoz-underground.contamateusfortnite.chatgpt.site/images/ama-2.webp'],'https://intactoz.com.br/products/camiseta-sidoka-se-vc-n-ama-preta')
on conflict (id) do nothing;

-- Bucket público de fotos dos produtos. Upload/gravação apenas com autenticação administrativa.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('intactoz-products','intactoz-products',true,5242880,array['image/webp','image/jpeg','image/png'])
on conflict(id) do nothing;
create policy "intactoz_product_images_public_read" on storage.objects for select to anon, authenticated using(bucket_id='intactoz-products');
create policy "intactoz_product_images_admin_insert" on storage.objects for insert to authenticated with check(bucket_id='intactoz-products' and public.is_intactoz_admin());
create policy "intactoz_product_images_admin_update" on storage.objects for update to authenticated using(bucket_id='intactoz-products' and public.is_intactoz_admin()) with check(bucket_id='intactoz-products' and public.is_intactoz_admin());
create policy "intactoz_product_images_admin_delete" on storage.objects for delete to authenticated using(bucket_id='intactoz-products' and public.is_intactoz_admin());

-- Depois de cadastrar/confirmar a conta que será administradora, execute à parte:
-- insert into public.intactoz_admin_users(user_id) values ('UUID-DO-USUARIO-NO-AUTH');
-- Não atribua permissões de admin através de metadados enviados pelo cliente.
