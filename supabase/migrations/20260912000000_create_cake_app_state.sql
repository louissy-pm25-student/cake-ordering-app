create table if not exists public.cake_app_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint cake_app_state_data_is_object check (jsonb_typeof(data) = 'object')
);

create table if not exists public.cake_products (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null,
  name text not null default '', description text not null default '',
  price numeric not null default 0, category text not null default '',
  available boolean not null default false, payload jsonb not null,
  updated_at timestamptz not null default now(), primary key (owner_id, record_id)
);
create table if not exists public.cake_variants (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, name text not null default '', product_id text,
  size text, flavor text, filling text, adjustment numeric not null default 0,
  payload jsonb not null, updated_at timestamptz not null default now(),
  primary key (owner_id, record_id)
);
create table if not exists public.cake_orders (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, customer text not null default '', email text,
  status text not null default 'pending', fulfilment_date date,
  total numeric not null default 0, payment_status text,
  payload jsonb not null, updated_at timestamptz not null default now(),
  primary key (owner_id, record_id)
);
create table if not exists public.cake_custom_requests (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, customer text not null default '', email text,
  status text not null default 'pending', requested_date date, quote numeric,
  payload jsonb not null, updated_at timestamptz not null default now(),
  primary key (owner_id, record_id)
);
create table if not exists public.cake_customers (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, name text not null default '', email text,
  phone text, address text, points integer not null default 0,
  payload jsonb not null, updated_at timestamptz not null default now(),
  primary key (owner_id, record_id)
);
create table if not exists public.cake_discount_codes (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, code text not null default '',
  percent numeric not null default 0, active boolean not null default false,
  payload jsonb not null, updated_at timestamptz not null default now(),
  primary key (owner_id, record_id)
);
create table if not exists public.cake_reviews (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, customer text, email text, rating integer,
  comment text, payload jsonb not null,
  updated_at timestamptz not null default now(), primary key (owner_id, record_id)
);
create table if not exists public.cake_delivery_zones (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, name text not null default '',
  fee numeric not null default 0, active boolean not null default false,
  payload jsonb not null, updated_at timestamptz not null default now(),
  primary key (owner_id, record_id)
);
create table if not exists public.cake_drivers (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, name text not null default '', phone text,
  active boolean not null default false, payload jsonb not null,
  updated_at timestamptz not null default now(), primary key (owner_id, record_id)
);
create table if not exists public.cake_admin_accounts (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, name text not null default '',
  username text not null, role text not null, active boolean not null default true,
  credential jsonb, payload jsonb not null,
  updated_at timestamptz not null default now(), primary key (owner_id, record_id)
);
create table if not exists public.cake_notifications (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, email text, title text, notification_date text,
  is_read boolean not null default false, payload jsonb not null,
  updated_at timestamptz not null default now(), primary key (owner_id, record_id)
);
create table if not exists public.cake_customer_accounts (
  owner_id uuid not null references auth.users(id) on delete cascade,
  record_id text not null, name text not null default '', username text not null,
  email text not null, phone text, gender text, credential jsonb not null,
  payload jsonb not null, updated_at timestamptz not null default now(),
  primary key (owner_id, record_id)
);
create table if not exists public.cake_customer_data (
  owner_id uuid not null references auth.users(id) on delete cascade,
  email text not null, cart jsonb not null default '[]'::jsonb,
  orders jsonb not null default '[]'::jsonb,
  profile jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(), primary key (owner_id, email)
);
create table if not exists public.cake_sessions (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  customer_email text, admin_username text,
  updated_at timestamptz not null default now()
);

alter table public.cake_app_state enable row level security;
alter table public.cake_products enable row level security;
alter table public.cake_variants enable row level security;
alter table public.cake_orders enable row level security;
alter table public.cake_custom_requests enable row level security;
alter table public.cake_customers enable row level security;
alter table public.cake_discount_codes enable row level security;
alter table public.cake_reviews enable row level security;
alter table public.cake_delivery_zones enable row level security;
alter table public.cake_drivers enable row level security;
alter table public.cake_admin_accounts enable row level security;
alter table public.cake_notifications enable row level security;
alter table public.cake_customer_accounts enable row level security;
alter table public.cake_customer_data enable row level security;
alter table public.cake_sessions enable row level security;

revoke all on public.cake_app_state, public.cake_products,
  public.cake_variants, public.cake_orders, public.cake_custom_requests,
  public.cake_customers, public.cake_discount_codes, public.cake_reviews,
  public.cake_delivery_zones, public.cake_drivers,
  public.cake_admin_accounts, public.cake_notifications,
  public.cake_customer_accounts, public.cake_customer_data,
  public.cake_sessions from anon;
grant select, insert, update on public.cake_app_state to authenticated;
grant select on public.cake_products, public.cake_variants, public.cake_orders,
  public.cake_custom_requests, public.cake_customers, public.cake_discount_codes,
  public.cake_reviews, public.cake_delivery_zones, public.cake_drivers,
  public.cake_admin_accounts, public.cake_notifications,
  public.cake_customer_accounts, public.cake_customer_data,
  public.cake_sessions to authenticated;

drop policy if exists "read own app state" on public.cake_app_state;
create policy "read own app state" on public.cake_app_state for select to authenticated
using ((select auth.uid()) = user_id);
drop policy if exists "create own app state" on public.cake_app_state;
create policy "create own app state" on public.cake_app_state for insert to authenticated
with check ((select auth.uid()) = user_id);
drop policy if exists "update own app state" on public.cake_app_state;
create policy "update own app state" on public.cake_app_state for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'cake_products','cake_variants','cake_orders','cake_custom_requests',
    'cake_customers','cake_discount_codes','cake_reviews','cake_delivery_zones',
    'cake_drivers','cake_admin_accounts','cake_notifications',
    'cake_customer_accounts','cake_customer_data','cake_sessions'
  ] loop
    execute format('drop policy if exists "read own rows" on public.%I', table_name);
    execute format(
      'create policy "read own rows" on public.%I for select to authenticated using ((select auth.uid()) = owner_id)',
      table_name
    );
  end loop;
end $$;

create or replace function public.sync_cake_app_tables()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare item jsonb;
declare customer_key text;
declare customer_value jsonb;
begin
  delete from public.cake_products where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,products}', '[]'::jsonb)) loop
    insert into public.cake_products values (
      new.user_id, item->>'id', coalesce(item->>'name',''), coalesce(item->>'description',''),
      coalesce(nullif(item->>'price','')::numeric,0), coalesce(item->>'category',''),
      coalesce((item->>'available')::boolean,false), item, now()
    );
  end loop;

  delete from public.cake_variants where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,variants}', '[]'::jsonb)) loop
    insert into public.cake_variants values (
      new.user_id, item->>'id', coalesce(item->>'name',''), item->>'product', item->>'size',
      item->>'flavor', item->>'filling', coalesce(nullif(item->>'adjustment','')::numeric,0), item, now()
    );
  end loop;

  delete from public.cake_orders where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,orders}', '[]'::jsonb)) loop
    insert into public.cake_orders values (
      new.user_id, item->>'id', coalesce(item->>'customer',''), item->>'email',
      coalesce(item->>'status','pending'), nullif(item->>'date','')::date,
      coalesce(nullif(item->>'total','')::numeric,0), item->>'paymentStatus', item, now()
    );
  end loop;

  delete from public.cake_custom_requests where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,requests}', '[]'::jsonb)) loop
    insert into public.cake_custom_requests values (
      new.user_id, item->>'id', coalesce(item->>'customer',''), item->>'email',
      coalesce(item->>'status','pending'), nullif(item->>'date','')::date,
      nullif(item->>'quote','')::numeric, item, now()
    );
  end loop;

  delete from public.cake_customers where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,customers}', '[]'::jsonb)) loop
    insert into public.cake_customers values (
      new.user_id, item->>'id', coalesce(item->>'name',''), item->>'email', item->>'phone',
      item->>'address', coalesce(nullif(item->>'points','')::integer,0), item, now()
    );
  end loop;

  delete from public.cake_discount_codes where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,codes}', '[]'::jsonb)) loop
    insert into public.cake_discount_codes values (
      new.user_id, item->>'id', coalesce(item->>'name',''),
      coalesce(nullif(item->>'percent','')::numeric,0), coalesce((item->>'active')::boolean,false), item, now()
    );
  end loop;

  delete from public.cake_reviews where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,reviews}', '[]'::jsonb)) loop
    insert into public.cake_reviews values (
      new.user_id, item->>'id', item->>'customer', item->>'email', nullif(item->>'rating','')::integer,
      item->>'comment', item, now()
    );
  end loop;

  delete from public.cake_delivery_zones where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,zones}', '[]'::jsonb)) loop
    insert into public.cake_delivery_zones values (
      new.user_id, item->>'id', coalesce(item->>'name',''), coalesce(nullif(item->>'fee','')::numeric,0),
      coalesce((item->>'active')::boolean,false), item, now()
    );
  end loop;

  delete from public.cake_drivers where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,drivers}', '[]'::jsonb)) loop
    insert into public.cake_drivers values (
      new.user_id, item->>'id', coalesce(item->>'name',''), item->>'phone',
      coalesce((item->>'active')::boolean,false), item, now()
    );
  end loop;

  delete from public.cake_admin_accounts where owner_id = new.user_id;
  insert into public.cake_admin_accounts values (
    new.user_id, 'owner', 'Owner', coalesce(new.data #>> '{admin,ownerUsername}','admin'),
    'owner', true, new.data #> '{admin,ownerCredential}',
    jsonb_build_object('username',coalesce(new.data #>> '{admin,ownerUsername}','admin'),'role','owner'), now()
  );
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,staff}', '[]'::jsonb)) loop
    insert into public.cake_admin_accounts values (
      new.user_id, item->>'id', coalesce(item->>'name',''), coalesce(item->>'username',''),
      coalesce(item->>'role','staff'), coalesce((item->>'active')::boolean,false),
      item->'credential', item - 'credential', now()
    );
  end loop;

  delete from public.cake_notifications where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data #> '{admin,notifications}', '[]'::jsonb)) loop
    insert into public.cake_notifications values (
      new.user_id, item->>'id', item->>'email', item->>'name', item->>'date',
      coalesce((item->>'read')::boolean,false), item, now()
    );
  end loop;

  delete from public.cake_customer_accounts where owner_id = new.user_id;
  for item in select value from jsonb_array_elements(coalesce(new.data->'accounts', '[]'::jsonb)) loop
    insert into public.cake_customer_accounts values (
      new.user_id, coalesce(item->>'email',item->>'username'), coalesce(item->>'name',''),
      coalesce(item->>'username',''), coalesce(item->>'email',''), item->>'phone', item->>'gender',
      jsonb_build_object('salt',item->'salt','passwordHash',item->'passwordHash'),
      item - 'salt' - 'passwordHash', now()
    );
  end loop;

  delete from public.cake_customer_data where owner_id = new.user_id;
  for customer_key, customer_value in select key, value from jsonb_each(coalesce(new.data->'users','{}'::jsonb)) loop
    insert into public.cake_customer_data values (
      new.user_id, customer_key, coalesce(customer_value->'cart','[]'::jsonb),
      coalesce(customer_value->'orders','[]'::jsonb), coalesce(customer_value->'profile','{}'::jsonb), now()
    );
  end loop;

  delete from public.cake_sessions where owner_id = new.user_id;
  insert into public.cake_sessions values (
    new.user_id, nullif(new.data #>> '{session,customerEmail}',''),
    nullif(new.data #>> '{session,adminUsername}',''), now()
  );
  return new;
end;
$$;

drop trigger if exists sync_cake_app_tables_trigger on public.cake_app_state;
create trigger sync_cake_app_tables_trigger
after insert or update of data on public.cake_app_state
for each row execute function public.sync_cake_app_tables();
