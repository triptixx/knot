#!/usr/bin/perl

use strict;
use XML::RPC;
use Data::Dumper;

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

my $api = XML::RPC->new($endpoint);
my $domains = $api->call('domain.list', $apikey);

chomp(my @domain = `/opt/knot/sbin/knotc conf-read zone.domain | awk '{print \$NF}'`);

for(@domain) {
  my $domain = $_;
  $domain =~ s/\.$//;

  chomp(my @output = `/opt/knot/sbin/keymgr $domain list | awk '\$2 == "ksk=yes" {gsub("tag=","",\$4);print \$4}' | sed 's/^[0]*//'`);

  my $found_domain = 0;
  for(@$domains) {
    if($_->{'fqdn'} eq $domain) {
      print "Domain $domain located in Gandi account\nChecking existing DNSSEC keys...\n";
      $found_domain++;

      my $keys = $api->call('domain.dnssec.list', $apikey, $domain);
      for(@$keys) {
        my $item = $_->{'keytag'};
        if(not grep {$_ eq $item} @output) {
          my $key_id = $_->{'id'};
          print "Located key id $key_id for $domain keytag $item\n";
          my $delete = $api->call('domain.dnssec.delete', $apikey, $key_id);
          print Dumper($delete)."\n";
        }
      }
    }
  }
  die "Didn't find $domain in account. Exiting.\n" unless $found_domain;
}
