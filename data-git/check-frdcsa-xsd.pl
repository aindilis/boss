#!/usr/bin/perl -w

foreach my $dir (qw(minor internal)) {
  foreach my $codebase (split /\n/, `ls -1 /var/lib/myfrdcsa/codebases/$dir/`) {
    my $xmlfile = "/var/lib/myfrdcsa/codebases/$dir/$codebase/frdcsa/FRDCSA.xml";
    if (! -f $xmlfile) {
      # print "$xmlfile does not exist\n";
    } else {
      print "$xmlfile exists\n";
      # foreach my $type (qw(simple complex)) {
      foreach my $type (qw(complex)) {
	my $xsdfile = "/var/lib/myfrdcsa/codebases/internal/boss/data-git/FRDCSA-$type.xsd";
	system("xmllint", "--noout", "--schema", $xsdfile, $xmlfile);
      }
    }
  }
}
