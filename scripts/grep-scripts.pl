#!/usr/bin/perl -w

use BOSS::ICodebase qw(GetSystems);

my @ok;
my $systems = GetSystems;
foreach my $sys (keys %$systems) {
  push @ok,@{FindAllPerlScripts($systems->{$sys})};
}
system "grep ".$ARGV[0]." ".join(" ",map {"\"$_\""} @ok);

sub FindAllPerlScripts {
  my $dir = shift;
  my @match;
  if (-d "$dir/scripts") {
    foreach my $f (split /\n/, `find "$dir/scripts"`) {
      if (-f $f) {
	my $res = `file $f`;
	if ($res =~ /perl/i) {
	  # print $f."\n";
	  push @match, $f;
	}
      }
    }
  }
  return \@match;
}
