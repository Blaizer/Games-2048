package Games::2048::Game;
use 5.01;
use Moo;

use Term::ANSIColor;
use POSIX qw/floor ceil/;
use List::Util qw/max min/;

extends 'Games::2048::Grid';

has start_tiles  => is => 'ro', default => 2;
has score        => is => 'rw', default => 0;
has moved        => is => 'rw', default => 0;
has needs_redraw => is => 'rw', default => 1;
has quit         => is => 'rw', default => 0;
has win          => is => 'rw', default => 0;
has lose         => is => 'rw', default => 0;
has keep_playing => is => 'rw', default => 0;
has restart      => is => 'rw', default => 0;

use constant {
	# colors
	BORDER_COLOR => "reverse",

	# dimensions
	BORDER_WIDTH => 2,
	BORDER_HEIGHT => 1,

	CELL_WIDTH => 7,
	CELL_HEIGHT => 3,
};

sub each_vector {
	(
		[ 0, -1],
		[ 0,  1],
		[ 1,  0],
		[-1,  0],
	);
}

sub key_vector {
	my ($self, $key) = @_;
	state $vectors = [ $self->each_vector ];
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

sub run {
	my $self = shift;
	$self->insert_random_tile for 1..$self->start_tiles;

	$self->draw;

	PLAY: while (1) {
		while (defined(my $key = Games::2048::Input::read_key)) {
			my $vec = $self->key_vector($key);
			if ($vec) {
				$self->move($vec);
			}
			elsif ($key =~ /^[q\e\cC]$/i) {
				$self->quit(1);
				last PLAY;
			}
			elsif ($key =~ /^[r]$/i) {
				$self->restart(1);
				last PLAY;
			}
		}

		if ($self->moved) {
			$self->moved(0);
			if (!$self->has_available_cells and !$self->has_available_merges) {
				$self->lose(1);
			}
		}

		if ($self->needs_redraw) {
			# restore cursor position to start of drawing
			printf "\e[%dA", $self->total_height;
			$self->draw;
		}

		if ($self->lose or $self->win) {
			my $message =
				$self->win ? "You win!"
				           : "Game over!";
			my $offset = floor(($self->total_width - length($message)) / 2);

			say " " x $offset, colored(uc $message, "bold"), "\n";

			last PLAY;
		}

		Games::2048::Input::delay;
	}
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
	my $moved = 0;

	for my $cell ($vec->[0] > 0 || $vec->[1] > 0 ? reverse $self->each_cell : $self->each_cell) {
		die if !ref $cell;
		my $tile = $self->tile($cell);
		next if !$tile;
		$tile->merged(0); # allow tiles to merge into this one

		my $next = $cell;
		my $farthest;
		do {
			$farthest = $next;
			$next = [ map $next->[$_] + $vec->[$_], 0..1 ];
		} while ($self->within_bounds($next)
		    and !$self->tile($next));

		if ($self->cells_can_merge($cell, $next)) {
			my $next_tile = $self->tile($next);
			my $value = $next_tile->value + $tile->value;
			$next_tile->value($value);
			$next_tile->merged(1); # disallow merging into this tile
			$self->clear_tile($cell);
			$self->score($self->score + $value);
			$self->win(1) if $value >= 2048 and !$self->keep_playing;
			$self->moved(1);
		}
		else {
			my $farthest_tile = $self->tile($farthest);
			if (!$farthest_tile) {
				$self->clear_tile($cell);
				$self->set_tile($farthest, $tile);
				$self->moved(1);
			}
		}
	}

	if ($self->moved) {
		$self->insert_random_tile;
		$self->needs_redraw(1);
	}
}

sub cells_can_merge {
	my ($self, $cell, $next) = @_;
	my $tile = $self->tile($cell);
	my $next_tile = $self->tile($next);
	$tile and $next_tile and !$next_tile->merged and $next_tile->value == $tile->value;
}

sub has_available_merges {
	my $self = shift;
	for my $vec ([0, 1], [1, 0]) {
		for my $cell ($self->each_cell) {
			my $next = [ map $cell->[$_] + $vec->[$_], 0..1 ];
			return 1 if $self->cells_can_merge($cell, $next);
		}
	}
}

sub draw {
	my $self = shift;

	$self->draw_border_horizontal;

	for my $y (0..$self->size-1) {
		for my $line (0..CELL_HEIGHT-1) {
			$self->draw_border_vertical;

			for my $x (0..$self->size-1) {
				my $tile = $self->tile([$x, $y]);

				if (defined $tile) {
					my $value = $tile->value;
					my $color = $self->tile_color($value);

					my $lines = min(ceil(length($value) / CELL_WIDTH), CELL_HEIGHT);
					my $first_line = floor((CELL_HEIGHT - $lines) / 2);
					my $this_line = $line - $first_line;

					if ($this_line >= 0 and $this_line < $lines) {
						my $cols = min(ceil(length($value) / $lines), CELL_WIDTH);
						my $string_offset = $this_line * $cols;
						my $string_length = min($cols, length($value) - $string_offset, CELL_WIDTH);
						my $cell_offset = floor((CELL_WIDTH - $string_length) / 2);

						$self->draw_tile($cell_offset, $color);

						my $string = substr($value, $string_offset, $string_length);
						print colored($string, $color);

						$self->draw_tile(CELL_WIDTH - $cell_offset - $string_length, $color);
					}
					else {
						$self->draw_tile(CELL_WIDTH, $color);
					}
				}
				else {
					$self->draw_tile(CELL_WIDTH);
				}
			}

			$self->draw_border_vertical;
			say "";
		}
	}

	$self->draw_border_horizontal;

	$self->needs_redraw(0);
}

sub tile_color {
	my ($self, $value) = @_;
	!defined $value  ? ""
	: $value <= 2    ? "reverse cyan"
	: $value <= 4    ? "reverse green"
	: $value <= 8    ? "reverse yellow"
	: $value <= 16   ? "reverse blue"
	: $value <= 32   ? "reverse magenta"
	: $value <= 64   ? "reverse red"
	: $value <= 2048 ? "reverse yellow"
	                 : "reverse bright_yellow";
}

sub total_width {
	my $self = shift;
	$self->size * CELL_WIDTH + BORDER_WIDTH * 2;
}

sub total_height {
	my $self = shift;
	$self->size * CELL_HEIGHT + BORDER_HEIGHT * 2;
}

sub draw_border_horizontal {
	my $self = shift;
	say colored(" " x $self->total_width, BORDER_COLOR);
}
sub draw_border_vertical {
	print colored("  ", BORDER_COLOR)
}

sub draw_tile {
	my ($self, $width, $color) = @_;
	return if $width < 1;
	my $string = " " x $width;
	print $color
		? colored($string, $color)
		: $string;
}

1;
