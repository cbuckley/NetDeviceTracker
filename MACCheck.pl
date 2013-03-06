use warnings;
use Net::Telnet();

my $password = `variables.cnf`;
my $routerADDR = "192.168.1.1";
my (@MAC,@arpTable);

while (true) {
@arpTable = getARPtable($routerADDR,$password);

open (my $devicesOldFile,"<","networkDevices.txt") or die "File didn't open very well";

foreach my $line (<$devicesOldFile>) {
	my @tmp = split (/,/,$line);
	my $macAddress = $tmp[0];
	push(@MAC,"$macAddress");
}
close ($devicesOldFile);

open (my $devicesFile,">","networkDevices.txt") or die "Couldn't open the file";
open (my $MACeventLog,">","eventLog.txt") or die "That didn't work very well";
foreach my $line (@arpTable) {
	if ($line =~ /(.{2}\:.{2}\:.{2}\:.{2}\:.{2}\:.{2})/) {
		if (checkMAC($1) eq 0) {
			`msg * New device $1 found`;
			print $MACeventLog "New device $1 at".(localtime);
		}
		print $devicesFile "$1";
	}
	if ($line =~ /(\d+\.\d+\.\d+\.\d+)/) {
		print $devicesFile ",$1\n";
	}
}

print "\n";
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
	$telnet->login("root","$password");
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
			print "Already know about $_[0]\n";
			return 1;
		}
	}
	print "$_[0] is a new one\n";
	return 0;
}