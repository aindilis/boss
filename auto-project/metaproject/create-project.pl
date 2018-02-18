#!/usr/bin/perl -w

# this idea should be updated and added to boss promote



# This  program performs  a set  of checks  whenever someone  wants to
# enter a new project.

#print "Checking whether similar capabilities exist on massive sources.list\n";
#print "apt-cache search ";

#print "\n";

#print "Checking whether similar capabilities exist on massive sources.list\n";
#print "apt-cache search ";

# for  now,  simply  copy  files into  appropriate  directory,  asking
# permission to do so first, also, cp with backups.

# determine appropriate directory

sub message ($) {
    print shift;
}

sub instruction ($) {
    print shift;
}

sub confirm_action {
    print shift() . "\n";
    instruction("Enter 'yes' to confirm action.");
    print "\n> ";
    $response = <>;
    if ($response =~ /^yes$/) {
	message("Action accepted.\n");
	return 1;
    }
    message("Action canceled.\n");
    return 0;
}

$templatedir = "/home/debs/prog/myfrdcsa/template/project";
$projectdirectory = `pwd`;
chomp $projectdirectory;
$project_name = $projectdirectory;
$project_name =~ s|.*/([^/]+)/?$|$1|;

print "<$project_name>\n";

if (confirm_action("Should we copy the project template into $projectdirectory?")) {
    print "cp -a --backup=numbered --reply=yes ${templatedir}/* $projectdirectory\n";
    system "cp -a --backup=numbered --reply=yes ${templatedir}/* $projectdirectory";

    # now go ahead and replace the files titled project-name.* with the actual name
    $files = `find . | grep "project-name"`;
    foreach $file (split(/\n/,$files)) {
	$newfile = $file;
	$newfile =~ s/project-name/project-$project_name/;
	print  "mv $file $newfile\n";
	system "mv $file $newfile";
    }
}

