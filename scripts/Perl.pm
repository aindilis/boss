################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Handler::Perl;

require Exporter;

use strict;

use Data::Dumper;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;

#---------------------------------------------------------------

#####################
# Constructor Methods

# new inherited from Autodia::Handler

#------------------------------------------------------------------------
# Access Methods

# parse_file inherited from Autodia::Handler

#-----------------------------------------------------------------------------
# Internal Methods

# _initialise inherited from Autodia::Handler

sub _parse {
    my $self     = shift;
    my $fh       = shift;
    my $filename = shift;
    my $Diagram  = $self->{Diagram};

    my $pkg_regexp = '[\w:]+';

    my $Class;

    # Class::Tangram bits
    $self->{_is_tangram_class} = {};
    $self->{_in_tangram_class} = 0;
    my $pat1 = '[\'\"]?\w+[\'\"]?\s*=>\s*\{.*?\}';
    my $pat2 = '[\'\"]?\w+[\'\"]?\s*=>\s*undef';

    # pod
    $self->{pod} = 0;

    my $filecontents = "";

    # parse through file looking for stuff
    foreach my $line (<$fh>) {
	$filecontents .= $line;
	chomp $line;
	if ($self->_discard_line($line)) {
	    next;
	}

	# if line contains package name then parse for class name
	if ($line =~ /^\s*package\s+($pkg_regexp)/) {
	    my $className = $1;
	    # create new class with name
	    $Class = Autodia::Diagram::Class->new($className);
	    # add class to diagram
	    $Class = $Diagram->add_class($Class);
	}

	if ($line =~ /^\s*use\s+base\s+(?:q|qw){0,1}\s*([\(\{\/\#])\s*(.*)\s*[\)\}\1]/) {
	    my $superclass = $2;

	    # check package exists before doing stuff
	    $self->_is_package(\$Class, $filename);

	    my @superclasses = split(/[\s*,]/, $superclass);

	    foreach my $super (@superclasses) # WHILE_SUPERCLASSES
		{
		    # discard if stopword
		    next if ($super =~ /(?:exporter|autoloader)/i);
		    # create superclass
		    my $Superclass = Autodia::Diagram::Superclass->new($super);
		    # add superclass to diagram


		    $self->{_is_tangram_class}{$Class->Name} = {state=>0} if ($super eq 'Class::Tangram');

		    my $exists_already = $Diagram->add_superclass($Superclass);
		    #	  warn "already exists ? $exists_already \n";
		    if (ref $exists_already) {
			$Superclass = $exists_already;
		    }
		    # create new inheritance
		    my $Inheritance = Autodia::Diagram::Inheritance->new($Class, $Superclass);
		    # add inheritance to superclass
		    $Superclass->add_inheritance($Inheritance);
		    # add inheritance to class
		    $Class->add_inheritance($Inheritance);
		    # add inheritance to diagram
		    $Diagram->add_inheritance($Inheritance);
		}
	    next;
	}

	# if line contains dependancy name then parse for module name
	if ($line =~ /^\s*(use|require)\s+($pkg_regexp)/) {
	    unless (ref $Class) {
		# create new class with name
		$Class = Autodia::Diagram::Class->new($filename);
		# add class to diagram
		$Class = $Diagram->add_class($Class);
	    }
	    my $componentName = $2;
	    # discard if stopword
	    next if ($componentName =~ /^(strict|vars|exporter|autoloader|warnings.*|constant.*|data::dumper|carp.*|overload|switch|\d|lib)$/i);

	    # check package exists before doing stuff
	    $self->_is_package(\$Class, $filename);


	    if ($componentName =~ /(fields|private|public)/) {
		my $pragma = $1;
		$line =~ /\sqw\((.*)\)/;
		my @fields = split(/\s+/,$1);
		foreach my $field (@fields) {
		    my $attribute_visibility = ( $field =~ m/^\_/ ) ? 1 : 0;
		    unless ($pragma eq 'fields') {
			$attribute_visibility = ($pragma eq 'private' ) ? 1 : 0;
		    }
		    $Class->add_attribute({
					   name => $field,
					   visibility => $attribute_visibility,
					  }) unless ($field =~ /^\$/);
		}
	    } else {
		# create component
		my $Component = Autodia::Diagram::Component->new($componentName);
		# add component to diagram
		my $exists = $Diagram->add_component($Component);

		# replace component if redundant
		if (ref $exists) {
		    $Component = $exists;
		}
		# create new dependancy
		my $Dependancy = Autodia::Diagram::Dependancy->new($Class, $Component);
		# add dependancy to diagram
		$Diagram->add_dependancy($Dependancy);
		# add dependancy to class
		$Class->add_dependancy($Dependancy);
		# add dependancy to component
		$Component->add_dependancy($Dependancy);
		next;
	    }
	}

	# if ISA in line then extract templates/superclasses
	if ($line =~ /^\s*\@(?:\w+\:\:)*ISA\s*\=\s*(?:q|qw){0,1}\((.*)\)/) {
	    my $superclass = $1;
      
	    #      warn "handling superclasses $1 with \@ISA\n";
	    #      warn "superclass line : $line \n";
	    if ($superclass) {
		# check package exists before doing stuff
		$self->_is_package(\$Class, $filename);

		my @superclasses = split(" ", $superclass);

		foreach my $super (@superclasses) # WHILE_SUPERCLASSES
		    {
			# discard if stopword
			next if ($super =~ /(?:exporter|autoloader)/i || !$super);
			# create superclass
			my $Superclass = Autodia::Diagram::Superclass->new($super);
			# add superclass to diagram
			my $exists_already = $Diagram->add_superclass($Superclass);
			#	      warn "already exists ? $exists_already \n";
			if (ref $exists_already) {
			    $Superclass = $exists_already;
			}
			$self->{_is_tangram_class}{$Class->Name} = {state=>0} if ($super eq 'Class::Tangram');
			# create new inheritance
			#	      warn "creating inheritance from superclass : $super\n";
			my $Inheritance = Autodia::Diagram::Inheritance->new($Class, $Superclass);
			# add inheritance to superclass
			$Superclass->add_inheritance($Inheritance);
			# add inheritance to class
			$Class->add_inheritance($Inheritance);
			# add inheritance to diagram
			$Diagram->add_inheritance($Inheritance);
		    }
	    } else {
		warn "ignoring empty \@ISA \n";
	    }
	}

	# Handle Class::Tangram classes
	if (ref $self) {
	    if ($line =~ /^\s*(?:our|my)?\s+\$fields\s(.*)$/ and defined $self->{_is_tangram_class}{$Class->Name}) {
		$self->{_field_string} = '';
		warn "tangram parser : found start of fields for ",$Class->Name,"\n";
		$self->{_field_string} = $1;
		warn "field_string : $self->{_field_string}\n";
		$self->{_in_tangram_class} = 1;
		if ( $line =~ /^(.*\}\s*;)/) {
		    warn "found end of fields for  ",$Class->Name,"\n";
		    $self->{_in_tangram_class} = 2;
		}
	    }
	    if ($self->{_in_tangram_class}) {

		if ( $line =~ /^(.*\}\s*;)/ && $self->{_in_tangram_class} == 1) {
		    warn "found end of fields for  ",$Class->Name,"\n";
		    $self->{_field_string} .= $1;
		    $self->{_in_tangram_class} = 2;
		} else {
		    warn "adding line to fields for  ",$Class->Name,"\n";
		    $self->{_field_string} .= $line unless ($self->{_in_tangram_class} == 2);
		}
		if ($self->{_in_tangram_class} == 2) {
		    warn "processing fields for ",$Class->Name,"\n";
		    $_ = $self->{_field_string};
		    s/^\s*\=\s*\{\s//;
		    s/\}\s*;$//;
		    s/[\s\n]+/ /g;
		    warn "fields : $_\n";
		    my %field_types = m/(\w+)\s*=>\s*[\{\[]\s*($pat1|$pat2|qw\([\w\s]+\))[\s,]*[\}\]]\s*,?\s*/g;

		    warn Dumper(field_types=>%field_types);
		    foreach my $field_type (keys %field_types) {
			warn "handling $field_type..\n";
			$_ = $field_types{$field_type};
			my $pat1 = '\'\w+\'\s*=>\s*\{.*?\}';
			my $pat2 = '\'\w+\'\s*=>\s*undef';
			my %fields;
			if (/qw\((.*)\)/) {
			    my $fields = $1;
			    warn "qw fields : $fields\n";
			    my @fields = split(/\s+/,$fields);
			    @fields{@fields} = @fields;
			} else {
			    %fields = m/[\'\"]?(\w+)[\'\"]?\s*=>\s*([\{\[].*?[\}\]]|undef)/g;
			}
			warn Dumper(fields=>%fields);
			foreach my $field (keys %fields) {
			    warn "found field : '$field' of type '$field_type' in (class ",$Class->Name,") : \n";
			    my $attribute = { name=>$field, type=>$field_type };
			    if ($fields{$field} =~ /class\s*=>\s*[\'\"](.*?)[\'\"]/) {
				$attribute->{type} = $1;
			    }
			    if ($fields{$field} =~ /init_default\s*=>\s*[\'\"](.*?)[\'\"]/) {
				$attribute->{default} = $1;
				# FIXME : attribute default values unsupported ?
			    }
			    $attribute->{visibility} = ( $attribute->{name} =~ m/^\_/ ) ? 1 : 0;

			    $Class->add_attribute($attribute);
			}

		    }
		    $self->{_in_tangram_class} = 0;
		}
	    }

	}
	# if line contains sub then parse for method data
	if ($line =~ /^\s*sub\s+?(\w+)/) {
	    my $subname = $1;

	    # check package exists before doing stuff
	    $self->_is_package(\$Class, $filename);

	    my %subroutine = ( "name" => $subname, );
	    $subroutine{"visibility"} = ($subroutine{"name"} =~ m/^\_/) ? 1 : 0;

	    # NOTE : perl doesn't provide named parameters
	    # if we wanted to be clever we could count the parameters
	    # see Autodia::Handler::PHP for an example of parameter handling

	    $Class->add_operation(\%subroutine);
	}

	# if line contains object attributes parse add to class
	if ($line =~ m/\$(class|self|this)\-\>\{['"]*(.*?)["']*}/) {
	    my $attribute_name = $2;
	    my $attribute_visibility = ( $attribute_name =~ m/^\_/ ) ? 1 : 0;

	    $Class->add_attribute({
				   name => $attribute_name,
				   visibility => $attribute_visibility,
				  }) unless ($attribute_name =~ /^\$/);
	}

	# add this block once can handle being entering & exiting subs:
	# if line contains possible args to method add them to method
	#	if (($line =~ m/^\([\w\s]+\)\s*\=\s*\@\_\;\s*$/) && ())
	#	  {
	#	    print "should be adding these arguments to sub : $1\n";
	#	  }

    }

    _extract_attributes($Class, $filecontents);

    $self->{Diagram} = $Diagram;
    close $fh;
    return;
}

sub _extract_attributes {
  my $Class = shift;
  my $c = shift;
  # my @m;
  if ($c =~ /use Class::MethodMaker.*get_set(.*?);/s) {
    my $s = $1;
    my @l = split /\W+/, $s;
    foreach my $i (@l) {
      if ($i !~ /^qw$/ and $i) {
	# push @m, $i;
	my $attribute_name = $i;
	my $attribute_visibility = ( $attribute_name =~ m/^\_/ ) ? 1 : 0;
	$Class->add_attribute({
			       name => $attribute_name,
			       visibility => $attribute_visibility,
			      });
      }
    }
  }
}

sub _discard_line
{
  my $self    = shift;
  my $line    = shift;
  my $discard = 0;

  SWITCH:
    {
	if ($line =~ m/^\s*$/) # if line is blank or white space discard
	{
	    $discard = 1;
	    last SWITCH;
	}

	if ($line =~ /^\s*\#/) # if line is a comment discard
	{
	    $discard = 1;
	    last SWITCH;
	}

	if ($line =~ /^\s*\=head/) # if line starts with pod syntax discard and flag with $pod
	{
	    $self->{pod} = 1;
	    $discard = 1;
	    last SWITCH;
	}

	if ($line =~ /^\s*\=cut/) # if line starts with pod end syntax then unflag and discard
	{
	    $self->{pod} = 0;
	    $discard = 1;
	    last SWITCH;
	}

	if ($self->{pod} == 1) # if line is part of pod then discard
	{
	    $discard = 1;
	    last SWITCH;
	}
    }
    return $discard;
}

####-----

sub _is_package
  {
    my $self    = shift;
    my $package = shift;
    my $Diagram = $self->{Diagram};

    unless(ref $$package)
       {
	 my $filename = shift;
	 # create new class with name
	 $$package = Autodia::Diagram::Class->new($filename);
	 # add class to diagram
	 $Diagram->add_class($$package);
       }

    return;
  }

####-----

1;

###############################################################################

=head1 NAME

Autodia::Handler::Perl.pm - AutoDia handler for perl

=head1 INTRODUCTION

HandlerPerl parses files into a Diagram Object, which all handlers use. The role of the handler is to parse through the file extracting information such as Class names, attributes, methods and properties.

HandlerPerl parses files using simple perl rules. A possible alternative would be to write HandlerCPerl to handle C style perl or HandleHairyPerl to handle hairy perl.

HandlerPerl is registered in the Autodia.pm module, which contains a hash of language names and the name of their respective language - in this case:

%language_handlers = { .. , perl => "perlHandler", .. };

=head1 CONSTRUCTION METHOD

use Autodia::Handler::Perl;

my $handler = Autodia::Handler::Perl->New(\%Config);

This creates a new handler using the Configuration hash to provide rules selected at the command line.

=head1 ACCESS METHODS

$handler->Parse(filename); # where filename includes full or relative path.

This parses the named file and returns 1 if successful or 0 if the file could not be opened.

$handler->output(); # any arguments are ignored.

This outputs the Dia XML file according to the rules in the %Config hash passed at initialisation of the object.

=cut






