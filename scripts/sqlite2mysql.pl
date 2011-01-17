#!/usr/local/bin/perl -w
use strict;
use 5.12.0;

use DBI;
use autodie;

my $db_sq = '/home/waltman/.irssi/db/messages.sqlite.save';

my $dbh_sq = DBI->connect("DBI:SQLite:$db_sq", '', '',
                          { PrintError=>1, RaiseError=>1, AutoCommit=>1 } );

my $db_my = 'irc';
my $dsn_my = "DBI:mysql:database=$db_my";

my $dbh_my = DBI->connect("$dsn_my", 'waltman', '',
                          { PrintError=>1, RaiseError=>1, AutoCommit=>1 } );

$dbh_my->begin_work;

copy_networks($dbh_sq, $dbh_my);
copy_channels($dbh_sq, $dbh_my);
copy_nicks($dbh_sq, $dbh_my);
copy_messages($dbh_sq, $dbh_my);

$dbh_my->commit;

sub copy_networks {
    my ($dbh_sq, $dbh_my) = @_;

    say "Copying networks...";

    my $in_sth = $dbh_sq->prepare('
SELECT network_id, network, datetime(time_added, "localtime")
FROM networks
');

    my $out_sth = $dbh_my->prepare('
INSERT INTO networks (network_id, network, time_added)
              VALUES (?,          ?,       ?)
');

    copy_data($in_sth, $out_sth);
}

sub copy_channels {
    my ($dbh_sq, $dbh_my) = @_;

    say "Copying channels...";

    my $in_sth = $dbh_sq->prepare('
SELECT channel_id, channel, datetime(time_added, "localtime")
FROM channels
');

    my $out_sth = $dbh_my->prepare('
INSERT INTO channels (channel_id, channel, time_added)
              VALUES (?,          ?,       ?)
');

    copy_data($in_sth, $out_sth);
}

sub copy_nicks {
    my ($dbh_sq, $dbh_my) = @_;

    say "Copying nicks...";

    my $in_sth = $dbh_sq->prepare('
SELECT nick_id, nick, datetime(time_added, "localtime")
FROM nicks
');

    my $out_sth = $dbh_my->prepare('
INSERT INTO nicks (nick_id, nick, time_added)
           VALUES (?,       ?,    ?)
');

    copy_data($in_sth, $out_sth);
}

sub copy_messages {
    my ($dbh_sq, $dbh_my) = @_;

    say "Copying messages...";

    my $in_sth = $dbh_sq->prepare('
SELECT message_id, network_id, channel_id, nick_id, message, datetime(time_added, "localtime")
FROM messages
');

    my $out_sth = $dbh_my->prepare('
INSERT INTO messages (message_id, network_id, channel_id, nick_id, message, time_added)
              VALUES (?,          ?,          ?,          ?,       ?,       ?)
');

    copy_data($in_sth, $out_sth);
}

sub copy_data {
    my ($in_sth, $out_sth) = @_;

    $in_sth->execute;

    while (my @f = $in_sth->fetchrow_array) {
        $out_sth->execute(@f);
    }
}
