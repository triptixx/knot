#!/usr/bin/perl

use strict;
use XML::RPC;
use Data::Dumper;
use Net::DNS;

my $config;
my @configs = qw|/etc/gandi.conf /usr/local/etc/gandi.conf ~/.gandirc /opt/knot/gandi.conf|;
for(@configs) {
  my $c = $_;
  if(-f $c) {
    if(open(C, $c)) {
      print "Loading config from $c\n";
      while(<C>) {
        next if m/^\s*#/;
        if(m/^(.*?)\s+(.*?)$/) {
          $config->{$1} = $2;
        }
      }
      close C;
    }
  }
}

my $endpoint = $config->{'endpoint'} || die "no endpoint in config file\n";
my $apikey = $config->{'apikey'} || die "no apikey in config file\n";

my @input = `/opt/knot/sbin/knotc zone-read loxoo.net @ CDNSKEY | cut -d' ' -f2-`;

for(@input) {
  chomp(my($domain, undef, undef, $flag, undef, $alg, $public_key) = split /\s+/, $_, 7);
  print "Domain: $domain\n";
  print "Flag: $flag\n";
  print "Alg: $alg\n";
  print "Key: $public_key\n";

  $domain =~ s/\.$//;

  my $rr = new Net::DNS::RR($_);
  my $keytag = $rr->keytag;
  print "Keytag: ".$keytag."\n";

  print "Connecting to Gandi API endpoint $endpoint\n";

  my $api = XML::RPC->new($endpoint);

  my $version = $api->call('version.info', $apikey);
  print "  Found API version: $version->{'api_version'}\n";

  my $domains = $api->call('domain.list', $apikey);
  my $found_domain = 0;
  for(@$domains) {
    if($_->{'fqdn'} eq $domain) {
      print "Domain $domain located in Gandi account\nChecking existing DNSSEC keys...\n";
      $found_domain++;

      my $keys = $api->call('domain.dnssec.list', $apikey, $domain);
      my $found_key = 0;
      for(@$keys) {
        if($_->{'keytag'} eq $keytag && $_->{'flags'} eq $flag && $_->{'public_key'} eq $public_key) {
          print "  Found existing matching key. No upload required.\n";
          $found_key++;
        }
      }

      if($found_domain && !$found_key) {
        print "Domain $domain found on account, key not found, so key needs uploading...\n";
        if(scalar(@$keys) >= 4) {
          print "  Gandi has 4 key limit. Currently found ".scalar(@$keys)." keys\n";
          exit 99;
        }
        my $params = {
          'flags' => $flag,
          'algorithm' => $alg,
          'public_key' => $public_key
        };
        my $key_add = $api->call('domain.dnssec.create', $apikey, $domain, $params);
        my $sub = `/opt/knot/sbin/knotc zone-ksk-submitted $domain`;
        print Dumper($key_add)."\n";
      }
    }
  }
  die "Didn't find $domain in account. Exiting.\n" unless $found_domain;
}
