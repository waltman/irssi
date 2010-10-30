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
        description => "log messages to a SQLite database",
        license     => "GPLv2",
        url         => "http://nchip.ukkosenjyly.mine.nu/irssiscripts/",
    );

my $db = '/home/waltman/.irssi/db/messages.sqlite';

my $dbh = DBI->connect("DBI:SQLite:$db", '', '',
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
INSERT INTO networks (network) VALUES (?)
');

my $nick_insert_sth = $dbh->prepare('
INSERT INTO nicks (nick) VALUES (?)
');

my $channel_insert_sth = $dbh->prepare('
INSERT INTO channels (channel) VALUES (?)
');

my $msg_insert_sth = $dbh->prepare('
INSERT INTO messages (network_id, nick_id, channel_id, message)
              VALUES (?,          ?,       ?,          ?)
');

sub cmd_logmsg {
    my ($server, $data, $nick, $mask, $target) = @_;
    db_insert($nick, $target, $data, $server->{tag});
    return 1;
}

sub cmd_own {
    my ($server, $data, $target) = @_;
    return cmd_logmsg($server, $data, $server->{nick}, "", $target);
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



sub db_insert {
    my ($nick, $target, $line, $network)=@_;

    $dbh->begin_work;

    my $network_id = get_id($network_check_sth, $network_insert_sth, $network);
    my $nick_id = get_id($nick_check_sth, $nick_insert_sth, $nick);
    my $channel_id = get_id($channel_check_sth, $channel_insert_sth, $target);

    $msg_insert_sth->execute($network_id, $nick_id, $channel_id, $line);

    $dbh->commit;
}

sub get_id {
    my ($check_sth, $insert_sth, $key) = @_;

    # check if we've already added it
    my ($id) = $dbh->selectrow_array($check_sth, undef, $key);

    return $id if defined $id;

    # add the row
    $insert_sth->execute($key);

    # return the auto-incremented id
    return $dbh->last_insert_id(undef, undef, undef, undef);
}

Irssi::signal_add_last('message public', 'cmd_logmsg');
Irssi::signal_add_last('message own_public', 'cmd_own');
Irssi::signal_add_last('message topic', 'cmd_topic');
Irssi::signal_add_last('message join', 'cmd_join');
#Irssi::signal_add_last('message notice', 'cmd_notice');
Irssi::signal_add_last('message part', 'cmd_part');
#Irssi::signal_add_first('message quit', 'cmd_quit');

Irssi::print("SQLite logger by waltman loaded.");


