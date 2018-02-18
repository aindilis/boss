use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'APP',
    VERSION_FROM    => 'APP.pm',
    ABSTRACT_FROM   => 'APP.pm',
    AUTHOR          => 'Andrew Dougherty <andrewdo@frdcsa.org>',
    PREREQ_PM       => {
			# 'Net::Bluetooth' => 0,
    },
);
