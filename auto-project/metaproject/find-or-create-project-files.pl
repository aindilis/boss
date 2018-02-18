#!/usr/bin/perl -w

# This program makes a skeleton project structure, without overwriting
# anything if some  of it exists.  It is mainly  used to jumpstart the
# project's documentation at this point Wed Jan 28 22:40:05 EST 2004

# This is a program that creates a project directory for a given name,
# and runs all of the hooks required of a new program.

# parse myfrdcsa.conf

# run helper  scripts to  manage all aspects  of the  debian directory
# that are changing,  so for instance, must sit down  and write the OO
# structure for the helper applications.

$myfrdcsa = {
    root => "",
};

$project = {
    name => "",
    directory => "",
};

@files = split /[\n\r]/, `find `;

foreach $file (@files) {
    $file =~ s/^project\/?//;
    if ($file ne "") {
	print "<$file>\n";
    }
}

