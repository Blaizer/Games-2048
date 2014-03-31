package Games::2048::Input;
use 5.01;
use strictures;

use Term::ANSIColor;
use Term::ReadKey;
use Time::HiRes;

END {
	ReadMode 0; # reset read mode on exit
}

ReadMode 4;           # Turn off controls keys
STDOUT->autoflush(1); # So output shows straight away
print color("reset"); # Just for safety

sub read_key {
	state @keys;

	if (@keys) {
		return shift @keys;
	}

	my $char;
	my $packet = '';
	while (defined($char = ReadKey(-1))) {
		$packet .= $char;
	}

	if ($packet =~ m(
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
		last if defined $key;
		Time::HiRes::sleep(Games::2048::FRAME_TIME);
	}
	return $key;
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

1;
