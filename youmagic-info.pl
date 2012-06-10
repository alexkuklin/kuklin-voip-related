#!/usr/bin/perl

use strict;

use LWP::UserAgent;
use Mojo::DOM;
use Switch;

if (!$ARGV[0]) {
	print "Usage: $0 (balance|calllog) login password\n";
	exit 1;
}

my $ua = LWP::UserAgent->new(cookie_jar => { file => "/tmp/.cookies.$$.txt" });

my $response = $ua->get('https://www.youmagic.com/index.php?option=com_portabillinguser&view=login');

my $dom = Mojo::DOM->new($response->decoded_content) || die;

my %reqhash;

my @inputs = $dom->find("#com-form-login")->[0]->find('input')->each;

foreach my $input (@inputs)
{
	next unless $input->attrs->{name};
	my $value = $input->attrs->{value};
	$value = $ARGV[1] if ($input->attrs->{name} eq 'username');
	$value = $ARGV[2] if ($input->attrs->{name} eq 'passwd');
	
	$reqhash{$input->attrs->{name}} = $value;
}

push @{ $ua->requests_redirectable }, 'POST';
$response = $ua->post( 'https://www.youmagic.com/en/component/portabillinguser/', \%reqhash);

switch ($ARGV[0]) {
	case 'balance' {
		$response = $ua->get( 'https://www.youmagic.com/en/account');

		$dom = Mojo::DOM->new($response->decoded_content);

		my $balancespan = $dom->find("div.balance-icon")->[0]->content_xml;
		my ($balanceval) = ( $balancespan =~ /(\d+\.\d\d) roubles/);
		print "$balanceval\n";

	}

	case 'calllog' {
		$response = $ua->get( 'https://www.youmagic.com/en/history');

		$dom = Mojo::DOM->new($response->decoded_content);

		my $lines = $dom->find("div#dialed div table tr");

		my $i=0;

		$lines->each(sub {
			$i++;
                        my $status = $_->find("td.f-cld")->[0]->attrs->{class};
			my $dest = $_->find("td.f-cld a")->[0]->text,
                        my $date = $_->find("td.time")->[0]->text; chop($date);
			my $time = $_->find("td.time b")->[0]->text;
			my $desttype = $_->find("td.destination div")->[0]->text;
                        my $duration = $_->find("td.duration")->[0]->text;
                        my $amount = $_->find("td.amount")->[0]->text;
                        print join("\t",( $i, $status, $dest, $date, $time, $desttype, $duration, $amount ));
			print "\n";

		});
	}
}

END { unlink("/tmp/.cookies.$$.txt"); }

