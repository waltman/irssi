begin transaction;

drop table if exists networks;

create table networks (
       network_id integer not null primary key autoincrement,
       network text unique,
       time_added integer NOT NULL DEFAULT CURRENT_TIMESTAMP
);

drop table if exists nicks;

create table nicks (
       nick_id integer not null primary key autoincrement,
       nick text unique,
       time_added integer NOT NULL DEFAULT CURRENT_TIMESTAMP
);

drop table if exists channels;

create table channels (
       channel_id integer not null primary key autoincrement,
       channel text unique,
       time_added integer NOT NULL DEFAULT CURRENT_TIMESTAMP
);

drop table if exists messages;

create table messages (
       message_id integer not null primary key autoincrement,
       network_id integer,
       nick_id integer,
       channel_id integer,
       message text,
       time_added integer NOT NULL DEFAULT CURRENT_TIMESTAMP
);

commit;
