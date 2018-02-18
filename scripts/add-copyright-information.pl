#!/usr/bin/perl -w

# script to add copyright information to files.

# one thing to do is insert  the copyright based on the files creation
# date

# another thing is to use our license

use DatTime;
use File::Stat;


sub AddCopyrightInformationToFile {
  foreach my $f (@_) {
    if (-f $f) {
      # get its creation time etc
      my $stat = File::Stat->new($f);
      # print join(",",(map {$stat->$_} qw(atime mtime ctime)),$f)."\n";
      my $dt = DateTime->from_epoch
	(epoch => $stat->ctime,
	 time_zone => 'America/New_York');
    }
  }
}

AddCopyrightInformationToFile(@ARGV);
