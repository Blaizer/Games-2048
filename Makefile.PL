use 5.01;
use strict;
use warnings;
use inc::Module::Install;

name     'Games-2048';
all_from 'lib/Games/2048.pm';
license  'perl';

perl_version 5.01;

resources (
	# homepage   => 'http://yourwebsitehere.com',
	# IRC        => 'irc://irc.perl.org/#Games-2048',
	license    => 'http://dev.perl.org/licenses/',
	repository => {
		type => 'git',
		url => 'git://github.com/Blaizer/Games-2048.git',
		web => 'https://github.com/Blaizer/Games-2048',
	},
	bugtracker => 'https://github.com/Blaizer/Games-2048/issues',
);

configure_requires (
);

build_requires (
);

test_requires (
);

requires (
	'Term::ReadKey'  => 0,
	'Moo'            => 0,
	'strictures'     => 0,
	'File::ShareDir' => 0,
	('Win32::Console::ANSI' => 0) x ($^O eq 'MSWin32'),
);

install_script (
	'2048',
);

install_as_cpan;
auto_install;
WriteAll;
