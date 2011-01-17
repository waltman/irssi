drop database if exists irc;
create database irc character set 'utf8' collate 'utf8_bin';

use irc;

start transaction;

drop table if exists networks;

create table networks (
       network_id integer unsigned not null primary key auto_increment,
       network varchar(32) not null unique,
       time_added datetime NOT NULL DEFAULT NOW()
) engine = innodb;

drop table if exists nicks;

create table nicks (
       nick_id integer unsigned not null primary key auto_increment,
       nick varchar(64) not null unique,
       time_added datetime NOT NULL DEFAULT NOW()
) engine = innodb;

drop table if exists channels;

create table channels (
       channel_id integer unsigned not null primary key auto_increment,
       channel varchar(32) not null unique,
       time_added datetime NOT NULL DEFAULT NOW()
) engine = innodb;

drop table if exists messages;

create table messages (
       message_id integer unsigned not null primary key auto_increment,
       network_id integer not null unsigned,
       channel_id integer unsigned,
       nick_id integer not null unsigned,
       message varchar(4096) not null,
       time_added datetime NOT NULL DEFAULT NOW(),
       foreign key (network_id) references networks(network_id) on delete cascade,
       foreign key (channel_id) references channels(channel_id) on delete cascade,
       foreign key (nick_id) references nicks(nick_id) on delete cascade
) engine = innodb;

commit;
