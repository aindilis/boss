#!/usr/bin/perl -w

# given a file, extract its methodmaker attributes (can't we just load
# it and check that way :)

use Data::Dumper;

sub ExtractAttributes {
  my $c = shift;
  my @m;
  if ($c =~ /use Class::MethodMaker.*get_set(.*?);/s) {
    my $s = $1;
    my @l = split /\W+/, $s;
    foreach my $i (@l) {
      if ($i !~ /^qw$/ and $i) {
	push @m, $i;
      }
    }
  }
  return \@m;
}

foreach my $file (@ARGV) {
  if (-f $file) {
    my $c = `cat $file`;
    print Dumper(ExtractAttributes($c));
  }
}
