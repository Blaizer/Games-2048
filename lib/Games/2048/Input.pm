package Games::2048::Input;
use 5.01;
use strictures;

use if $^O eq "MSWin32", "Win32::Console::ANSI";
use Term::ReadKey;
use Time::HiRes;

END {
	ReadMode 0; # reset read mode on exit
}

ReadMode 4; # turn off control keys

# manual and automatic window size updating
my $_window_size;
$SIG{WINCH} = \&update_window_size;
&update_window_size;

sub read_key {
	state @keys;

	if (@keys) {
		return shift @keys;
	}

	my $char;
	my $packet = '';
	while (defined($char = ReadKey -1)) {
		$packet .= $char;
	}

	while ($packet =~ m(
		\G(
			\e [[O]        # CSI - \e[ or \eO
			[\x30-\x3f]*   # Parameter Bytes
			[\x20-\x2f]*   # Intermediate Bytes
			[\x40-\x7e]    # Final Byte
		|
			.              # Otherwise just any character
		)
	)gsx) {
		push @keys, $1;
	}

	return shift @keys;
}

sub poll_key {
	my $key;
	while (1) {
		$key = read_key;
		return $key if defined $key;
		Time::HiRes::sleep(Games::2048::FRAME_TIME);
	}
}

sub key_vector {
	my ($key) = @_;
	state $vectors = [ [0, -1], [0, 1], [1, 0], [-1, 0] ];
	state $keys    = [ map "\e[$_", "A".."D" ];
	my $vector;
	for (0..3) {
		if ($key eq $keys->[$_]) {
			$vector = $vectors->[$_];
			last;
		}
	}
	$vector;
}

sub update_window_size {
	($_window_size) = GetTerminalSize *STDOUT;
	$_window_size //= 80;
}

sub window_size {
	$_window_size;
}

1;
