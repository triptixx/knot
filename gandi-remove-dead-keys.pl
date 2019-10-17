#!/usr/bin/perl

use strict;
use XML::RPC;
use Data::Dumper;

my $endpoint = $ENV{'ENDPOINT'} || die "no endpoint in environnement system\n";
my $apikey = $ENV{'APIKEY'} || die "no apikey in environnement system\n";

print "Connecting to Gandi API endpoint $endpoint\n";
my $api = XML::RPC->new($endpoint);
my $version = $api->call('version.info', $apikey);
print "  Found API version: $version->{'api_version'}\n";

my $domains = $api->call('domain.list', $apikey);

chomp(my @domain = `/knot/sbin/knotc conf-read zone.domain | awk '{print \$NF}'`);

for(@domain) {
    my $domain = $_;
    $domain =~ s/\.$//;

    chomp(my @output = `/knot/sbin/keymgr $domain list | awk '\$2 == "ksk=yes" {gsub("tag=","",\$4);print \$4}'
        | sed 's/^[0]*//'`);

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
