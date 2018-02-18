#!/usr/bin/perl -w

# iterate across internal codebases

# generate makefile

my $perldir = "usr/share/perl5";

@dirs = [
	 "usr/bin",
	 $perldir,
	];

foreach my $dir (qw(doc etc var)) {
  if ( -e $dir) {

    push @dirs, "usr/share/$name/doc";
	 "$perldir";
  }
}

@makefilerules = [
		  # copy all executables in the homedir to /usr/bin
		  "cp $(DESTDIR)/usr/bin",
		  # if it exists
		  "cp -ar doc $(DESTDIR)/usr/share/doc/$name",
		  "cp scripts/* $(DESTDIR)/usr/bin",
		  "cp -ar $perlfiles $(DESTDIR)/$perldir",
		  # if it exists
		  "cp -ar data $(DESTDIR)/$perldir",
		  # copy any emacs file to the appropriate place
		  # cp any etc,var files to an appropriate place
		 ];
