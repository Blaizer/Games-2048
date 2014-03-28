package Games::2048::Input;
use 5.01;
use strictures;

use Term::ReadKey;
use Time::HiRes;

END {
	say '';
	ReadMode 0; # reset read mode on exit
}

ReadMode 4;           # Turn off controls keys
STDOUT->autoflush(1); # So output shows straight away

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

sub delay {
	Time::HiRes::sleep(1/100);
}

sub poll_key {
	my $key;
	while (!defined $key) {
		$key = read_key;
		delay;
	}
	return $key;
}

1;
