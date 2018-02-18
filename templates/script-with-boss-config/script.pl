#!/usr/bin/perl -w

use BOSS::Config;
use PerlLib::SwissArmyKnife;

$specification = q(
	-l		List existing searches
	-d <depth>	Number or results to include in search
	--or		Split the topic into a bunch of tokens ORed together
	<search>...	Searches to be acted upon
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";

if (! exists $conf->{'--or'}) {

}
