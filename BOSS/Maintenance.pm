package BOSS::Maintenance;

# files status is alpha

use MyFRDCSA qw ( Dir );

sub Execute {
  MakeEtags();
}

sub CleanSandbox {
  # checks which sandbox dirs are removable

  # first, which ones have not been made into packages already

  # secondly, which ones have not been modified from source

  # what is the source package

  # obtain a diff between the source package and the expanded

  # if the differences are in excess of some preset thresholds, show the
  # user the differences, have them choose whether to keep them
}

sub GlimpseSearch {
  if (!ArchiveRecentlyUpdated() ||
      ExplicitlyInstructedTo()) {
    UpdateArchive();
  } else {
    Search();
  }
}

sub MakeEtags {
  # first rm the tags table
  # make list of all files that should be etagged
  my $tagsfile = "$UNIVERSAL::systemdir/data/TAGS";
  system "rm \"$tagsfile\"";
  print "Making TAGS\n";

  # first get all the FRDCSA files

  chdir "/usr/share/perl5";
  my $c = "find .  -follow | grep '\.p[lm]\$' | etags -o $tagsfile -a -";
  print "$c\n";
  system $c;

  # system "find .  -follow | grep '\.p[lm]$' | etags -L -";
  # chdir "/usr/share/emacs/site-lisp";
  # system "find . | grep '\.el$' | etags -L -";

}

sub GenPerlSymlinks {
  # make it so this generates update.sh,  but warn people to edit it for
  # correctness, eventually, use something  like critic to have it learn
  # which one's it is missing

  my $localperl = "/usr/local/share/perl";
  my $sourcedir = MyFRDCSA::Dir("internal codebases");
  my $version = "5.8.8";
  my @accepted;
  my $method = "better";

  # find $localperl/$version -follow | grep '\.pm$' | xargs ls -al  | sort -nrk5

  if ($method =~ /better/) {
    print "#!/bin/sh\n\n";
    my $files = `find $sourcedir | grep pm`;
    foreach my $file (split /\n/, $files) {
      $file =~ s/^$sourcedir\/(([^\/]+\/){2}).*/$1/;
      $uniq{$file} = 1;
    }
    foreach my $file (keys %uniq) {
      print "ln -s $sourcedir/$file $localperl/$version\n" if ($file =~ /^[^\/]+\/[A-Z]/);
    }
  } else {
    foreach my $project (split /\n/, `ls $sourcedir`) {
      foreach my $object (split /\n/, `ls $sourcedir/$project`) {
	if (-d "$sourcedir/$project/$object") {
	  my $fail = 0;
	  my $empty = 1;
	  my @files = split /\n/, `find $sourcedir/$project/$object`;
	  while (@files && ! $fail) {
	    my $file = pop @files;
	    if (-f $file) {
	      $type = `file $file`;
	      if ($type =~ /(Perl5 module source text)/) {
		$empty = 0;
	      }
	      if ($type !~ /(Perl5 module source text|perl script text executable|ASCII English text)/) {
		$fail = 1;
	      }
	    }
	  }
	  if (! $empty and ! $fail) {
	    push @accepted, "$sourcedir/$project/$object";
	  }
	}
      }
    }
    print "#!/bin/sh\n\n";
    foreach $directory (@accepted) {
      print "ln -s $directory /usr/local/share/perl/$version\n";
    }
  }
}

1;
