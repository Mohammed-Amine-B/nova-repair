create table if not exists public.tracking_installations (
  id uuid primary key default gen_random_uuid(),
  public_shop_id text not null,
  installation_secret_hash text not null,
  is_enabled boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint tracking_installations_public_shop_id_length
    check (char_length(btrim(public_shop_id)) between 1 and 128),
  constraint tracking_installations_secret_hash_format
    check (installation_secret_hash ~ '^[0-9a-f]{64}$')
);

create unique index if not exists tracking_installations_public_shop_id_key
  on public.tracking_installations (public_shop_id);

create table if not exists public.public_repair_tracking (
  tracking_token text not null,
  contract_version integer not null,
  public_shop_id text not null,
  shop_name text not null,
  shop_subtitle text,
  repair_code text not null,
  device_display_name text not null,
  status text not null,
  customer_message text,
  received_at timestamp with time zone not null,
  source_updated_at timestamp with time zone not null,
  published_at timestamp with time zone not null default now(),
  constraint public_repair_tracking_contract_version_supported
    check (contract_version = 1),
  constraint public_repair_tracking_public_shop_id_length
    check (char_length(btrim(public_shop_id)) between 1 and 128),
  constraint public_repair_tracking_tracking_token_length
    check (char_length(btrim(tracking_token)) between 1 and 256),
  constraint public_repair_tracking_shop_name_length
    check (char_length(btrim(shop_name)) between 1 and 160),
  constraint public_repair_tracking_shop_subtitle_length
    check (shop_subtitle is null or char_length(shop_subtitle) <= 240),
  constraint public_repair_tracking_repair_code_length
    check (char_length(btrim(repair_code)) between 1 and 100),
  constraint public_repair_tracking_device_display_name_length
    check (char_length(btrim(device_display_name)) between 1 and 300),
  constraint public_repair_tracking_customer_message_length
    check (customer_message is null or char_length(customer_message) <= 2000),
  constraint public_repair_tracking_status_allowed
    check (
      status in (
        'received',
        'diagnosing',
        'waiting_for_customer_approval',
        'waiting_for_part',
        'repairing',
        'ready_for_pickup',
        'delivered',
        'cancelled'
      )
    )
);

create unique index if not exists public_repair_tracking_tracking_token_key
  on public.public_repair_tracking (tracking_token);

create index if not exists public_repair_tracking_public_shop_id_idx
  on public.public_repair_tracking (public_shop_id);

create or replace function public.set_tracking_installation_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tracking_installations_set_updated_at
  on public.tracking_installations;

create trigger tracking_installations_set_updated_at
before update on public.tracking_installations
for each row
execute function public.set_tracking_installation_updated_at();

create or replace function public.publish_public_repair_tracking(
  p_tracking_token text,
  p_contract_version integer,
  p_public_shop_id text,
  p_shop_name text,
  p_shop_subtitle text,
  p_repair_code text,
  p_device_display_name text,
  p_status text,
  p_customer_message text,
  p_received_at timestamp with time zone,
  p_source_updated_at timestamp with time zone
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_row public.public_repair_tracking%rowtype;
begin
  select *
    into existing_row
    from public.public_repair_tracking
   where tracking_token = p_tracking_token
   for update;

  if found then
    if existing_row.public_shop_id <> p_public_shop_id then
      raise exception 'tracking token belongs to another shop'
        using errcode = '42501';
    end if;

    if p_source_updated_at < existing_row.source_updated_at then
      return 'ignored_stale';
    end if;

    if p_source_updated_at = existing_row.source_updated_at then
      return 'already_current';
    end if;

    update public.public_repair_tracking
       set contract_version = p_contract_version,
           shop_name = p_shop_name,
           shop_subtitle = p_shop_subtitle,
           repair_code = p_repair_code,
           device_display_name = p_device_display_name,
           status = p_status,
           customer_message = p_customer_message,
           received_at = p_received_at,
           source_updated_at = p_source_updated_at,
           published_at = now()
     where tracking_token = p_tracking_token;

    return 'published';
  end if;

  insert into public.public_repair_tracking (
    tracking_token,
    contract_version,
    public_shop_id,
    shop_name,
    shop_subtitle,
    repair_code,
    device_display_name,
    status,
    customer_message,
    received_at,
    source_updated_at,
    published_at
  ) values (
    p_tracking_token,
    p_contract_version,
    p_public_shop_id,
    p_shop_name,
    p_shop_subtitle,
    p_repair_code,
    p_device_display_name,
    p_status,
    p_customer_message,
    p_received_at,
    p_source_updated_at,
    now()
  );

  return 'published';
end;
$$;

alter table public.tracking_installations enable row level security;
alter table public.public_repair_tracking enable row level security;

revoke all on table public.tracking_installations from anon, authenticated;
revoke all on table public.public_repair_tracking from anon, authenticated;
revoke execute on function public.publish_public_repair_tracking(
  text,
  integer,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  timestamp with time zone,
  timestamp with time zone
) from public, anon, authenticated;

grant execute on function public.publish_public_repair_tracking(
  text,
  integer,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  timestamp with time zone,
  timestamp with time zone
) to service_role;
