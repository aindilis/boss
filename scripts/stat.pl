#!/usr/bin/perl -w

# program to print out cool statistics for my project:

use MyFRDCSA;

use Data::Dumper;

sub ObtainProjectInformation {
  my (%args) = @_;
  my $dir = Dir("internal codebases");
  my @icodebases = `ls $dir`;
  $dir = Dir("external codebases");
  my @ecodebases = `ls $dir`;
  $dir = Dir("binary packages");
  my @binarypackages = `ls $dir`;
  my $retval = "";
  $retval .= "SUMMARY\n";
  $retval .= "ICodebases:\t".scalar @icodebases."\n".
    "ECodebases:\t".scalar @ecodebases."\n".
      "Bin Packages:\t".scalar @binarypackages."\n";
  $retval .= LOCCount();
  return $retval;
}

sub LOCCount {
  my (%args) = @_;
  my $r = `cd /var/lib/myfrdcsa/codebases/internal/boss/perl-codebases && sloccount --follow .`;
  if ($r =~ /.*?(Total Physical Source .*)/s) {
    return $1;
  }
}

print ObtainProjectInformation;
