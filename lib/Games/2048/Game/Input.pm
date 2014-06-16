package Games::2048::Game::Input;
use 5.012;
use Moo;

extends 'Games::2048::Game';

sub handle_input {
	my ($self, $app) = @_;

	while (defined(my $key = Games::2048::Util::read_key)) {
		my $vec = Games::2048::Util::key_vector($key);
		if ($vec) {
			$app->move($vec);
		}
		elsif ($key =~ /^[q]$/i) {
			$app->quit(1);
		}
		elsif ($key =~ /^[r]$/i) {
			$app->restart(1);
		}
		elsif ($key =~ /^[a]$/i) {
			$app->no_animations(!$app->no_animations);
		}
	}
}

sub handle_finish {
	my ($self, $app) = @_;

	while (1) {
		my $key = Games::2048::Util::poll_key;
		if ($key =~ /^[nq]$/i) {
			$app->quit(1);
			return;
		}
		elsif ($key =~ /^[yr\n]$/i) {
			return;
		}
	}
}

1;
