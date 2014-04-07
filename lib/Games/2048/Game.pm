package Games::2048::Game;
use 5.012;
use Moo;

# increment this whenever we break compat with older game objects
our $VERSION = '0.02';

use Storable;
use File::Spec::Functions;
use File::HomeDir;

extends 'Games::2048::Board';

has won     => is => 'rw', default => 0;
has version => is => 'rw', default => __PACKAGE__->VERSION;

sub insert_start_tiles {
	my ($self, $start_tiles) = @_;
	$self->insert_random_tile for 1..$start_tiles;
}

sub insert_random_tile {
	my $self = shift;
	my @available_cells = $self->available_cells;
	return if !@available_cells;
	my $cell = $available_cells[rand @available_cells];
	my $value = rand() < 0.9 ? 2 : 4;
	$self->insert_tile($cell, $value);
}

sub move_tiles {
	my ($self, $vec) = @_;
	my $moved;

	my $reverse = $vec->[0] > 0 || $vec->[1] > 0;

	for my $cell (sort { $reverse } $self->tile_cells) {
		my $tile = $self->tile($cell);
		my $next = $cell;
		my $farthest;
		do {
			$farthest = $next;
			$next = [ map $next->[$_] + $vec->[$_], 0..1 ];
		} while ($self->within_bounds($next)
		    and !$self->tile($next));

		if ($self->cells_can_merge($cell, $next)) {
			# merge
			my $next_tile = $self->tile($next);

			$tile->moving_from($cell);

			$tile->merging_tiles(undef);
			$tile->appear(undef);
			$next_tile->merging_tiles(undef);
			$next_tile->appear(undef);

			my $merged_tile = Games::2048::Tile->new(
				value => $tile->value + $next_tile->value,
				merging_tiles => [ sort { $reverse } $tile, $next_tile ],
				merged => 1,
			);

			$self->clear_tile($cell);
			$self->set_tile($next, $merged_tile);

			$self->score($self->score + $merged_tile->value);
			$self->best_score($self->score) if $self->score > $self->best_score;
			if ($merged_tile->value >= 2048 and !$self->won) {
				$self->win(1);
				$self->won(1);
			}
			$moved = 1;
		}
		elsif (!$self->tile($farthest)) {
			# slide
			$tile->moving_from($cell);
			$tile->merging_tiles(undef);
			$tile->appear(undef);

			$self->clear_tile($cell);
			$self->set_tile($farthest, $tile);
			$moved = 1;
		}
	}

	$_->merged(0) for $self->each_tile;

	return $moved;
}

sub move {
	my ($self, $vec) = @_;
	if ($self->move_tiles($vec)) {
		$self->insert_random_tile;

		$self->needs_redraw(1);
		$self->moving_vec($vec);
		$self->moving(Games::2048::Animation->new(
			duration => 0.2,
		));

		if (!$self->has_moves_remaining) {
			$self->lose(1);
		}
	}
}

sub cells_can_merge {
	my ($self, $cell, $next) = @_;
	my $tile = $self->tile($cell);
	my $next_tile = $self->tile($next);
	$tile and $next_tile and !$next_tile->merged and $next_tile->value == $tile->value;
}

sub has_moves_remaining {
	my $self = shift;
	return 1 if $self->has_available_cells;
	for my $vec ([0, -1], [-1, 0]) {
		for my $cell ($self->each_cell) {
			my $next = [ map $cell->[$_] + $vec->[$_], 0..1 ];
			return 1 if $self->cells_can_merge($cell, $next);
		}
	}
	return;
}

sub _game_file {
	state $dir = eval {
		my $my_dist_method = "my_dist_" . ($^O eq "MSWin32" ? "data" : "config");
		File::HomeDir->$my_dist_method("Games-2048", {create => 1});
	};
	return if !defined $dir;
	return catfile($dir, "game.dat");
}

sub save {
	my $self = shift;
	$self->version(__PACKAGE__->VERSION);
	eval { store($self, _game_file); 1 };
}

sub restore {
	my $self = eval { retrieve(_game_file) };
	$self;
}

sub is_valid {
	my $self = shift;
	defined $self->version and $self->version >= __PACKAGE__->VERSION;
}

1;
