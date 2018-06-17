#!/usr/bin/perl
use Sys::Syslog qw(:standard :macros);
use LWP::UserAgent;
use JSON;
use Data::Dumper;


my $relay_domains_file = '/etc/postfix/relay_domains.pcre';
my $recipient_maps_file = '/etc/postfix/recipient_maps.pcre';

my $allUsers = $ENV{'ALLUSERS'} || 0;


if (length $ENV{'APIHOST'} <= 0 or length $ENV{'APIMETHOD'} <= 0 or length $ENV{'APIKEY'} <= 0) {
  die('Missing one or more of following env: APIHOST,APIMETHOD,APIKEY');
}

openlog("fetch_accounts.pl fetching", 'noeol,nonul');
syslog('info', 'Getting data from: %s', $ENV{'APIHOST'} );
closelog();

my @aliases = api('alias');
my @mailboxes = api('mailbox');

my @accounts = ();
foreach my $alias (@{ $aliases[0] }) {
  if ($alias->{'active_int'} == 1) {
    $email = $alias->{'address'};
    $email =~ s/\./\\./g;
    push @accounts, $email;
  }
}


my @domains = ();
foreach my $mailbox (@{ $mailboxes[0] }) {
  if ($mailbox->{'active_int'} == 1) { 
    push @domains, $mailbox->{'domain'};
    $email = $mailbox->{'username'};
    $email =~ s/\./\\./g;
    push @accounts, $email;
  }
}


if (scalar @accounts > 0 and $allUsers == 0) {
  truncate $recipient_maps_file, 0;  
  open (my $handle,'>>',$recipient_maps_file) or die("Cant open $recipient_maps_file");
  foreach my $account ( uniq(@accounts) ) {  
    my $pcre = '/^'.$account.'$/ OK'."\n";
    print $handle $pcre; 
    syslog('info', 'Alias: %s', $pcre);
  }
  close ($handle);
}

if (scalar @domains > 0) {
  truncate $relay_domains_file, 0;
  open (my $handle,'>>',$relay_domains_file) or die("Cant open $relay_domains_file");
  foreach my $domain ( uniq(@domains) ) {
    $domain =~ s/\./\\./g;
    my $pcre = '/^'.$domain.'$/ PERMIT'."\n";
    print $handle $pcre;
    syslog('info', 'Domain: %s', $pcre);
  }
  close ($handle);
  `/usr/sbin/postfix reload`;
}


sub uniq {
  my %seen;
  grep !$seen{$_}++, @_;
}

sub api {
  my ($api) = @_;
  my $response; 

  my $url = $ENV{'APIMETHOD'}."://".$ENV{'APIHOST'}."/api/v1/get/".$api."/all";

  my $headers = "X-API-KEY: ".$ENV{'APIKEY'};

  my $ua = new LWP::UserAgent;
  my $request = new HTTP::Request('GET', $url);
  $request->header('X-API-KEY' => $ENV{'APIKEY'});
  my $response = $ua->request($request);

  if ($response->is_success) {
    return decode_json $response->decoded_content;
  } else {
    print STDERR $response->status_line, "\n";
    return 1;
  }

}

