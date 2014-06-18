package Games::2048::Game::Loser;
use 5.012;
use Moo;

extends 'Games::2048::Game::Input';

use Storable qw/dclone/;

my @vecs = ([-1, 0], [1, 0], [0, -1], [0, 1]);
my @names = qw/left right up down/;

has toggle    => is => 'rw', default => 0;
has toggle_xy => is => 'rw', default => 0;
has lowest    => is => 'rw', default => 0;

sub BUILD {
	my $self = shift;
	$self->no_animations(1);
}

sub handle_input {
	my ($self, $app) = @_;

	if ($self->score > 96) {
		$app->restart(1);
		return;
	}

	my @order = 0..3;
	if ($self->toggle) {
		$order[0]++;
		$order[1]--;
		$order[2]++;
		$order[3]--;
	}
	if ($self->toggle_xy) {
		$order[0] += 2;
		$order[1] += 2;
		$order[2] -= 2;
		$order[3] -= 2;
	}

	my $lowest_score = "INF";
	my $lowest;

	for (0..3) {
		my $game = dclone $self;
		$game->move($vecs[$order[$_]]) or next;

		if ($game->score < $lowest_score) {
			$lowest_score = $game->score;
			$lowest = $_;
		}
	}

	$self->move($vecs[$order[$lowest]]);
	$self->lowest($lowest);

	if (not $lowest & 1) {
		$self->toggle(!$self->toggle);
	}
	if ($lowest > 1) {
		$self->toggle_xy(!$self->toggle_xy);
	}

	$self->next::method($app);
}

sub draw_score {
	my $self = shift;
	$self->score_height(2);

	printf "lowest: %d, toggle: %d, toggle_xy: %d\n",
		$self->lowest, $self->toggle, $self->toggle_xy;

	$self->next::method;
}

# disable vector input from the user
sub handle_input_key_vector {}

1;
