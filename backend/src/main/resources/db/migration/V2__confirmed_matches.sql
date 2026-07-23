create table if not exists matches (
 id bigserial primary key,
 profile_id bigint not null references profiles(id) on delete cascade,
 requester_name varchar(120) not null,
 room_id bigint not null references chat_rooms(id) on delete cascade,
 status varchar(30) not null default 'CONFIRMED' check(status in ('CONFIRMED','CANCELLED')),
 confirmed_at timestamptz not null default now(),
 unique(profile_id, requester_name)
);

create index if not exists idx_matches_room on matches(room_id);
