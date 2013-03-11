use warnings;
use Net::Telnet();
use HTTP::Request;
use LWP::UserAgent;
use Socket;
use DBI;
use Data::Dumper;
use Config::Simple;

$cfg = new Config::Simple('variables.cnf');

my (@MAC,@arpTable);
my ($tmpMAC,$tmpIP, $tmpDNSname,$routerADDR,$variables);

my $dbtype = $cfg->param('dbtype');
my $dbname = $cfg->param('dbname');
my $dbhost = $cfg->param('dbhost');
my $dbuser = $cfg->param('dbuser');
my $dbpass = $cfg->param('dbpass');

my $dbh = DBI->connect("DBI:$dbtype:$dbname:$dbhost", $dbuser, $dbpass) or die "Can't connect to db";
$sql = "select v_value as value, v_name from variables";
$sth = $dbh->prepare($sql);
$sth->execute() or die "Error";
$variables = $sth->fetchall_hashref("v_name");
$routerADDR = "$variables->{host}{value}";


while (1) {
undef @MAC;
undef @arpTable;
@arpTable = getARPtable($routerADDR);

#Opening connection to the DB server to grab the devices table
$sql = "select distinct(d_mac) from devices";
$sth = $dbh->prepare($sql);
$sth->execute() or die "Error";
my $MACT = $sth->fetchall_arrayref();

while ( my ($key, $value) = each($MACT) ) {
	push (@MAC, $value->[0]);
}

foreach my $line (@arpTable) {
	if ($line =~ /(.{2}\:.{2}\:.{2}\:.{2}\:.{2}\:.{2})/) {
		if (checkMAC($1)) {
			if($variables->{pushingbox_api}{value})	{
				pushingBox($variables->{pushingbox_api}{value}, $1);
			}
			$tmpMAC = $1;
			if ($line =~ /(\d+\.\d+\.\d+\.\d+)/) {
				$tmpIP = $1;
				$tmpDNSname = gethostbyaddr(inet_aton($tmpIP), AF_INET);
				$tmpDNSname = ($tmpDNSname) ? $tmpDNSname : "UNKNOWN";
			}
			$tmpDNSname = ($tmpDNSname) ? $tmpDNSname : "UNKNOWN";
			$sql = "insert into `devices` (`d_mac`, `d_ip`, `d_dns`) values (?,?,?)";
			$sth = $dbh->prepare($sql);
			$sth->execute($tmpMAC, $tmpIP, $tmpDNSname) or die "Error";
			$sql = "insert into `log` (`l_mac`, `l_ip`, `l_dns`) values (?,?,?)";
			$sth = $dbh->prepare($sql);
			$sth->execute($tmpMAC, $tmpIP, $tmpDNSname) or die "Error";

			`msg * New device $tmpMAC found called $tmpDNSname`;
			print "New device $tmpMAC @ $tmpIP ($tmpDNSname) -".(localtime)."\n";		
		}
	}

}
sleep (10);
}
sub getARPtable {
	my $telnet;
	my $msg;
	my @lines;
	$telnet = new Net::Telnet(Timeout=>10,Errmode=>'die');
	if (! defined $telnet) {
		die "Unable to create telnet object";
	}
	$telnet->open("$_[0]");
	if ( $msg = $telnet->errmsg) {
		die "Unable to open telnet to $msg";
	}
	sleep (2);
	$telnet->login("$variables->{username}{value}","$variables->{password}{value}");
	sleep (1);
	if ($msg = $telnet->errmsg) {
		die "Unable to login to $msg ";
	}
	my @arpOutput = $telnet->cmd("cat /proc/net/arp");
	$telnet->close();
	return @arpOutput;
}

sub checkMAC {
	foreach my $MACaddr (@MAC) {
		if ($MACaddr eq $_[0]) {
			return 0;
		}
	}
	return 1;
}

sub pushingBox	{
				my $URL = "http://api.pushingbox.com/pushingbox?devid=$_[0]&device=$_[1]";
				my $agent = LWP::UserAgent->new(env_proxy => 1,keep_alive => 1, timeout => 30); 
				my $header = HTTP::Request->new(GET => $URL); 
				my $request = HTTP::Request->new('GET', $URL, $header); 
				my $response = $agent->request($request);
}