package Games::2048::Input;
use 5.012;
use strictures;

use if $^O eq "MSWin32", "Win32::Console::ANSI";
use Term::ReadKey;
use Time::HiRes;

eval 'END { ReadMode "normal" }';
ReadMode "cbreak";

# manual and automatic window size updating
my $_window_size;
my $_window_size_is_automatic = eval { $SIG{WINCH} = \&update_window_size; 1 };

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

	push @keys, $packet =~ m(
		\G(
			\e \[          # CSI
			[\x30-\x3f]*   # Parameter Bytes
			[\x20-\x2f]*   # Intermediate Bytes
			[\x40-\x7e]    # Final Byte
		|
			.              # Otherwise just any character
		)
	)gsx;

	return shift @keys;
}

sub poll_key {
	while (1) {
		my $key = read_key;
		return $key if defined $key;
		Time::HiRes::sleep(Games::2048::FRAME_TIME);
	}
	return;
}

sub key_vector {
	my ($key) = @_;
	state $vectors = [ [0, -1], [0, 1], [1, 0], [-1, 0] ];
	state $keys = [ map "\e[$_", "A".."D" ];
	for (0..3) {
		return $vectors->[$_] if $key eq $keys->[$_];
	}
	return;
}

sub update_window_size {
	($_window_size) = eval { GetTerminalSize *STDOUT };
	$_window_size //= 80;
}

sub window_size {
	$_window_size;
}

sub window_size_is_automatic {
	$_window_size_is_automatic;
}

1;
