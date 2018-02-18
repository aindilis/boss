#!/usr/bin/perl -w

use BOSS::Config;

use Data::Dumper;

my $config = BOSS::Config->new
  (ConfFile => "reasonbase.conf");

print Dumper($config);
