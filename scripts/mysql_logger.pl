use DBI;
use Irssi;
use Irssi::Irc;
use autodie;

use vars qw($VERSION %IRSSI);

$VERSION = "1.0";
%IRSSI = (
        authors     => "Walt Mankowski",
        contact     => "waltman\@pobox.com",
        name        => "wcm_test",
        description => "log messages to a MySQL database",
        license     => "GPLv2",
        url         => "http://nchip.ukkosenjyly.mine.nu/irssiscripts/",
    );

my $db = 'irc';
my $dsn = "DBI:mysql:database=$db";

my $dbh = DBI->connect("$dsn", 'waltman', '',
                       { PrintError=>1, RaiseError=>1, AutoCommit=>1 } );

my $network_check_sth = $dbh->prepare('
SELECT network_id FROM networks WHERE network = ?
');

my $nick_check_sth = $dbh->prepare('
SELECT nick_id FROM nicks WHERE nick = ?
');

my $channel_check_sth = $dbh->prepare('
SELECT channel_id FROM channels WHERE channel = ?
');

my $network_insert_sth = $dbh->prepare('
INSERT IGNORE INTO networks (network, time_added) VALUES (?, NOW())
');

my $nick_insert_sth = $dbh->prepare('
INSERT IGNORE INTO nicks (nick, time_added) VALUES (?, NOW())
');

my $channel_insert_sth = $dbh->prepare('
INSERT IGNORE INTO channels (channel, time_added) VALUES (?, NOW())
');

my $msg_insert_sth = $dbh->prepare('
INSERT INTO messages (network_id, nick_id, channel_id, message, time_added)
              VALUES (?,          ?,       ?,          ?,       NOW())
');

sub cmd_logmsg {
    my ($server, $data, $nick, $mask, $target) = @_;
    db_insert($nick, $target, $data, $server->{tag});
    return 1;
}

sub cmd_action {
    my ($server, $data, $nick, $mask, $target) = @_;

    my $msg = "$nick $data";
    db_insert($nick, $target, $msg, $server->{tag});
    return 1;
}

sub cmd_own {
    my ($server, $data, $target) = @_;
    return cmd_logmsg($server, $data, $server->{nick}, "", $target);
}

sub cmd_own_action {
    my ($server, $data, $target) = @_;

    my $msg = "$server->{nick} $data";
    return cmd_logmsg($server, $msg, $server->{nick}, "", $target);
}

sub cmd_topic {
    my ($server, $target, $data, $nick, $mask) = @_;

    my $msg = "topic changed to '$data'";
    return cmd_logmsg($server, $msg, $nick, $mask, $target);
}

sub cmd_join {
    my ($server, $target, $nick, $mask) = @_;

    my $msg = "join: $nick";
    return cmd_logmsg($server, $msg, $nick, $mask, $target);
}

sub cmd_part {
    my ($server, $target, $nick, $mask, $reason) = @_;

    my $msg = "part: $nick [$reason]";
    return cmd_logmsg($server, $msg, $nick, $mask, $target);
}

sub cmd_quit {
    my ($server, $nick, $mask, $reason) = @_;

    my $msg = "quit: $nick [$reason]";
    return cmd_logmsg($server, $msg, $nick, $mask, undef);
}

sub cmd_kick {
    my ($server, $target, $nick, $knick, $mask, $reason) = @_;

    my $msg = "kick: $nick by $knick [$reason]";
    return cmd_logmsg($server, $msg, $nick, $mask, $target);
}


sub db_insert {
    my ($nick, $target, $line, $network)=@_;

    $dbh->begin_work;

    my $network_id = get_id($network_check_sth, $network_insert_sth, $network);
    my $nick_id = get_id($nick_check_sth, $nick_insert_sth, $nick);

    my $channel_id;
    if (defined $target) {
        $channel_id = get_id($channel_check_sth, $channel_insert_sth, $target);
    }

    $msg_insert_sth->execute($network_id, $nick_id, $channel_id, $line);

    $dbh->commit;
}

sub get_id {
    my ($check_sth, $insert_sth, $key) = @_;

    # check if we've already added it
    my ($id) = $dbh->selectrow_array($check_sth, undef, $key);
    return $id if defined $id;

    # try to add the row
    $insert_sth->execute($key);

    # return the id
    # note: I'm not using last_insert_id in case of a race condition
    #       in the insert
    return $dbh->selectrow_array($check_sth, undef, $key);
}

Irssi::signal_add_last('message public', 'cmd_logmsg');
Irssi::signal_add_last('message own_public', 'cmd_own');
Irssi::signal_add_last('message irc action', 'cmd_action');
Irssi::signal_add_last('message irc own_action', 'cmd_own_action');
Irssi::signal_add_last('message topic', 'cmd_topic');
Irssi::signal_add_last('message join', 'cmd_join');
#Irssi::signal_add_last('message notice', 'cmd_notice');
Irssi::signal_add_last('message part', 'cmd_part');
Irssi::signal_add_first('message quit', 'cmd_quit');
Irssi::signal_add_last('message kick', 'cmd_kick');

Irssi::print("SQLite logger by waltman loaded.");


