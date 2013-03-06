use warnings;
use Net::Telnet();
use Mail::Sendmail;
use HTTP::Request;
use LWP::UserAgent;
use Socket;

 if (!-e "variables.cnf") {
	die("No variables file exists, Terminating\n");
 }
 if (!-e "networkDevices.txt") {
	open FILE, ">networkDevices.txt" or die $!;
	close FILE;
 }

my @variables;
 open ($variables, 'variables.cnf');
 while (<$variables>) {
 	chomp;
	push(@variables, $_);
 }
 close ($variables);

my $routerADDR = "$variables[2]";
my (@MAC,@arpTable);
my ($tmpMAC,$tmpIP, $tmpDNSname);

while (1) {
undef @MAC;
undef @arpTable;
@arpTable = getARPtable($routerADDR);

open (my $devicesOldFile,"<","networkDevices.txt") or die "File didn't open very well";
foreach my $line (<$devicesOldFile>) {
	my @tmp = split (/,/,$line);
	my $macAddress = $tmp[0];
	push(@MAC,"$macAddress");
}
close ($devicesOldFile);

open (my $devicesFile,">>","networkDevices.txt") or die "Couldn't open the file";
open (my $MACeventLog,">>","eventLog.txt") or die "That didn't work very well";
foreach my $line (@arpTable) {
	if ($line =~ /(.{2}\:.{2}\:.{2}\:.{2}\:.{2}\:.{2})/) {
		if (checkMAC($1)) {
			if($variables[4])	{
				pushingBox($variables[4], $1);
			}
			$tmpMAC = $1;
			print $devicesFile "$tmpMAC";
			if ($line =~ /(\d+\.\d+\.\d+\.\d+)/) {
				$tmpIP = $1;
				print $devicesFile ",$tmpIP";
				$tmpDNSname = gethostbyaddr(inet_aton($tmpIP), AF_INET);
				$tmpDNSname = ($tmpDNSname) ? $tmpDNSname : "UNKNOWN";
				print $devicesFile ",$tmpDNSname\n";
			}
			$tmpDNSname = ($tmpDNSname) ? $tmpDNSname : "UNKNOWN";
			print $MACeventLog "New device $tmpMAC @ $tmpIP ($tmpDNSname) -".(localtime)."\n";
			`msg * New device $tmpMAC found called $tmpDNSname`;
			print "New device $tmpMAC @ $tmpIP ($tmpDNSname) -".(localtime)."\n";
		
		}

	}

}
close ($devicesFile);
close ($MACeventLog);

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
	$telnet->login("$variables[1]","$variables[0]");
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