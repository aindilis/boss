#!/usr/bin/perl -w

my (%dirs, @files);

foreach my $file (split /\n/,`cat metrics`) {
  push @files, $file;
  $dir = $file;
  $dir =~ s|^(.*)/.*$|$1|;
  $dirs{$dir} = $dir;
}

foreach my $dir (keys %dirs) {
  print "mkdirhier cache/$dir\n";
  system "mkdirhier cache/$dir";
}

foreach my $file (@files) {
  print "cp ../$file cache/$file\n";
  system "cp ../$file cache/$file";
}
