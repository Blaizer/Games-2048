package Games::2048::Game;
use 5.01;
use Moo;

extends 'Games::2048::Board';

has won => is => 'rw', default => 0;

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
	my $tile = Games::2048::Tile->new(value => $value);
	$self->set_tile($cell, $tile);
}

sub move {
	my ($self, $vec) = @_;
	my $moved;

	for my $cell ($vec->[0] > 0 || $vec->[1] > 0 ? reverse $self->tile_cells : $self->tile_cells) {
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
			my $value = $next_tile->value + $tile->value;
			$next_tile->value($value);
			$next_tile->merged(1); # disallow merging into this tile
			$self->clear_tile($cell);
			$self->score($self->score + $value);
			$self->best_score($self->score) if $self->score > $self->best_score;
			if ($value >= 2048 and !$self->won) {
				$self->win(1);
				$self->won(1);
			}
			$moved = 1;
		}
		else {
			# slide
			my $farthest_tile = $self->tile($farthest);
			if (!$farthest_tile) {
				$self->clear_tile($cell);
				$self->set_tile($farthest, $tile);
				$moved = 1;
			}
		}
	}

	if ($moved) {
		$self->insert_random_tile;

		# reallow merging
		$self->tile($_)->merged(0) for $self->tile_cells;

		if (!$self->has_moves_remaining) {
			$self->lose(1);
		}

		$self->needs_redraw(1);
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

1;
