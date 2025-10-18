-- Supabase schema for Laundry app (profiles, services, orders, order_items, comments)

-- profiles (linked to auth.users)
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text,
  phone text,
  address text,
  created_at timestamptz default now()
);

-- services
create table if not exists services (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  base_price numeric not null,
  created_at timestamptz default now()
);

-- orders
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete set null,
  service_id uuid references services(id) on delete set null,
  instructions text,
  pickup_time timestamptz,
  delivery_time timestamptz,
  status text default 'pending',
  total numeric,
  created_at timestamptz default now()
);

-- order_items
create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  name text,
  quantity int,
  price numeric
);

-- comments
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  user_id uuid references profiles(id) on delete set null,
  text text,
  rating int,
  created_at timestamptz default now()
);
