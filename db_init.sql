create table if not exists users (
  id bigserial primary key,
  tg_user_id bigint unique not null,
  created_at timestamptz default now()
);

create table if not exists channels (
  id bigserial primary key,
  tg_chat_id bigint not null,
  owner_tg_user_id bigint not null,
  title text, username text, is_admin boolean default false,
  unique (tg_chat_id, owner_tg_user_id)
);

create table if not exists channel_links (
  id bigserial primary key,
  owner_tg_user_id bigint not null,
  source_chat_id bigint not null,
  target_chat_id bigint not null,
  enabled boolean default true,
  paid_until timestamptz, -- доступ активен, если now() < paid_until
  unique (owner_tg_user_id, source_chat_id, target_chat_id)
);

-- до 6 правил на link
create table if not exists rules (
  id bigserial primary key,
  link_id bigint not null references channel_links(id) on delete cascade,
  idx int not null,               -- порядок 1..6
  type text not null,             -- simple|regex|hashtag_map|url_swap
  data jsonb not null,
  unique (link_id, idx)
);

-- исключения на link (строки, хэштеги, эмодзи) — если совпало, пропускаем пост
create table if not exists link_exclusions (
  id bigserial primary key,
  link_id bigint not null references channel_links(id) on delete cascade,
  token text not null,
  unique (link_id, token)
);

-- соответствие для правок
create table if not exists messages_map (
  id bigserial primary key,
  link_id bigint not null references channel_links(id) on delete cascade,
  source_msg_id bigint not null,
  target_msg_id bigint not null,
  media_group_id text,
  unique (link_id, source_msg_id)
);

-- платежи (журнал фактов)
create table if not exists payments (
  id bigserial primary key,
  owner_tg_user_id bigint not null,
  link_id bigint not null references channel_links(id) on delete cascade,
  amount bigint not null,             -- в миним. единицах (копейки)
  currency text not null,
  provider_payload jsonb,
  paid_at timestamptz default now()
);

-- индексы
create index if not exists idx_links_source on channel_links(source_chat_id);
create index if not exists idx_rules_link on rules(link_id, idx);
create index if not exists idx_excl_link on link_exclusions(link_id);
create index if not exists idx_map_link on messages_map(link_id, source_msg_id);
create index if not exists idx_pay_user on payments(owner_tg_user_id, link_id, paid_at);

