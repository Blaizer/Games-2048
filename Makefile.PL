use 5.01;
use strict;
use warnings;
use inc::Module::Install;

name     'Games-2048';
all_from 'lib/Games/2048.pm';
author   'Blaise Roth <blaizer@cpan.org>';
license  'perl';

perl_version 5.01;

resources (
	# homepage   => 'http://yourwebsitehere.com',
	# IRC        => 'irc://irc.perl.org/#Games-2048',
	license    => 'http://dev.perl.org/licenses/',
	repository => 'https://github.com/Blaizer/Games-2048',
	bugtracker => 'https://github.com/Blaizer/Games-2048/issues',
);

configure_requires (
);

build_requires (
);

test_requires (
);

requires (
	'Term::ReadKey' => 0,
	'Moo'           => 0,
);

install_as_cpan;
auto_install;
WriteAll;
