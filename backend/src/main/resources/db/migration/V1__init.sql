create table if not exists profiles (
 id bigserial primary key,name varchar(120) not null,age integer not null check(age between 18 and 100),role varchar(160) not null,district varchar(120) not null,budget integer not null check(budget>0),distance numeric(7,2) not null default 0,avatar text not null,verified boolean not null default false,bio text not null,traits text not null default '',red_flags text not null default '',created_at timestamptz not null default now()
);
create table if not exists listings (
 id bigserial primary key,title varchar(240) not null,address varchar(240) not null,district varchar(120) not null,price integer not null check(price>0),rooms integer not null check(rooms>0),area integer not null check(area>0),distance numeric(7,2) not null default 0,slots integer not null check(slots>0),image text not null,owner varchar(120) not null,resident_name varchar(120),traits text not null default '',red_flags text not null default '',created_at timestamptz not null default now()
);
create table if not exists chat_rooms (
 id bigserial primary key,room_type varchar(30) not null check(room_type in ('PERSON','LISTING')),listing_id bigint references listings(id) on delete cascade,profile_id bigint references profiles(id) on delete cascade,title varchar(240) not null,created_at timestamptz not null default now()
);
create table if not exists chat_messages (
 id bigserial primary key,room_id bigint not null references chat_rooms(id) on delete cascade,sender varchar(120) not null,message_text text not null,created_at timestamptz not null default now()
);
create index if not exists idx_listings_district_price on listings(district,price);
create index if not exists idx_profiles_district_budget on profiles(district,budget);
create index if not exists idx_chat_messages_room_created on chat_messages(room_id,created_at);
