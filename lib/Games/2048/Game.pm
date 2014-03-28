package Games::2048::Game;
use 5.01;
use Moo;

use Term::ANSIColor;
use POSIX qw/floor ceil/;
use List::Util qw/max min/;

has grid         => is => 'lazy';
has size         => is => 'ro', default => 4;
has start_tiles  => is => 'ro', default => 2;
has score        => is => 'rw', default => 0;
has needs_redraw => is => 'rw', default => 1;

use constant {
	# colors
	BORDER_COLOR => "reverse",

	# dimensions
	BORDER_WIDTH => 2,
	BORDER_HEIGHT => 1,

	CELL_WIDTH => 7,
	CELL_HEIGHT => 3,
};

sub _build_grid {
	my $self = shift;
	Games::2048::Grid->new(size => $self->size);
}

sub run {
	my $self = shift;
	$self->insert_random_tile for 1..$self->start_tiles;
	$self->draw;
}

sub insert_random_tile {
	my $self = shift;
	my @available_cells = $self->grid->available_cells;
	return if !@available_cells;
	my $cell = $available_cells[rand @available_cells];
	my $value = rand() < 0.9 ? 2 : 4;
	my $tile = Games::2048::Tile->new(value => $value);
	$self->grid->cells->[$cell->[1]][$cell->[0]] = $tile;
}

sub draw {
	my $self = shift;

	$self->draw_border_horizontal;

	for my $y (0..$self->size-1) {
		for my $line (0..CELL_HEIGHT-1) {
			$self->draw_border_vertical;

			for my $x (0..$self->size-1) {
				my $tile = $self->grid->cells->[$y][$x];

				if (defined $tile) {
					my $value = $tile->value;
					my $color = $self->tile_color($value);

					my $lines = min(ceil(length($value) / CELL_WIDTH), CELL_HEIGHT);
					my $first_line = floor(CELL_HEIGHT - $lines) / 2;
					my $this_line = $line - $first_line;

					if ($this_line >= 0 and $this_line < $lines) {
						my $cols = min(ceil(length($value) / $lines), CELL_WIDTH);
						my $string_offset = $this_line * $cols;
						my $string_length = min($cols, length($value) - $string_offset, CELL_WIDTH);
						my $cell_offset = floor(CELL_WIDTH - $string_length) / 2;

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

sub draw_border_horizontal {
	my $self = shift;
	say colored(" " x ($self->size * CELL_WIDTH + BORDER_WIDTH * 2), BORDER_COLOR);
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
