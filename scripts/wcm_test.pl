#
# Logs URLs this script is just a hack. hack it to suit you
# if you want to.
#
# table format;
#
#+-----------+---------------+------+-----+---------+-------+
#| Field     | Type          | Null | Key | Default | Extra |
#+-----------+---------------+------+-----+---------+-------+
#| insertime | timestamp(14) | YES  |     | NULL    |       |
#| nick      | char(10)      | YES  |     | NULL    |       |
#| target    | char(255)     | YES  |     | NULL    |       |
#| line      | char(255)     | YES  |     | NULL    |       |
#+-----------+---------------+------+-----+---------+-------+


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
        description => "test how signals and suchlike work",
        license     => "GPLv2",
        url         => "http://nchip.ukkosenjyly.mine.nu/irssiscripts/",
    );

$dsn = 'DBI:mysql:ircurl:localhost';
$db_user_name = 'tunnus';
$db_password = 'salakala';
$db = '/tmp/irssi_test.sqlite';
$log = '/tmp/irssi_test.txt';

sub cmd_logurl {
	my ($server, $data, $nick, $mask, $target) = @_;
        db_insert($nick, $target, $data, $server);
#         $d = $data;
#         if (($d =~ /(.{1,2}tp\:\/\/.+)/) or ($d =~ /(www\..+)/)) {
# 		db_insert($nick, $target, $1);
#         }
	return 1;
}

sub cmd_own {
	my ($server, $data, $target) = @_;
	return cmd_logurl($server, $data, $server->{nick}, "", $target);
}
sub cmd_topic {
	my ($server, $target, $data, $nick, $mask, $server) = @_;
	return cmd_logurl($server, $data, $nick, $mask, $target);
}

sub db_insert {
	my ($nick, $target, $line, $server)=@_;
#	my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
        my $dbh = DBI->connect("DBI:SQLite:$db", '', '',
                               { PrintError=>1, RaiseError=>1, AutoCommit=>1 } );
	my $sql="insert into urlevent (insertime, nick, target,line) values (NOW()".",". $dbh->quote($nick) ."," . $dbh->quote($target) ."," . $dbh->quote($line) .")";
#	my $sth = $dbh->do($sql);

#         my $keys = join ", ", keys %{$server};
#         $sql .= " keys='$keys'";
        $sql .= " chatnet = $server->{chatnet}, tag = $server->{tag}";

        open my $fh, '>>', $log;
        print $fh "$sql\n";
	$dbh->disconnect();
	}

Irssi::signal_add_last('message public', 'cmd_logurl');
Irssi::signal_add_last('message own_public', 'cmd_own');
Irssi::signal_add_last('message topic', 'cmd_topic');

Irssi::print("URL logger by lite/nchip loaded.");


