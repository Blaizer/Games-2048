package Games::2048::Board;
use 5.01;
use Moo;

use Term::ANSIColor;
use POSIX qw/floor ceil/;
use List::Util qw/max min/;

extends 'Games::2048::Grid';

has score        => is => 'rw', default => 0;
has best_score   => is => 'rw', default => 0;
has needs_redraw => is => 'rw', default => 1;

use constant {
	# colors
	BORDER_COLOR => "reverse",

	# dimensions
	BORDER_WIDTH => 2,
	BORDER_HEIGHT => 1,

	CELL_WIDTH => 7,
	CELL_HEIGHT => 3,

	SCORE_INNER_PADDING => 2,
};

sub draw {
	my $self = shift;

	$self->draw_score;
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

sub draw_win {
	my ($self, $win) = @_;
	my $message =
		$win ? "You win!"
		     : "Game over!";
	my $offset = floor(($self->board_width - length($message)) / 2);

	say " " x $offset, colored(uc $message, "bold"), "\n";
}

sub draw_score {
	my ($self) = @_;

	my $score = "Score:";
	my $best_score = "Best score:";

	my $blank_width = $self->board_width - length($score) - length($best_score);
	my $score_width = floor(($blank_width - SCORE_INNER_PADDING) / 2);
	my $inner_padding = $blank_width - $score_width * 2;

	$self->draw_sub_score($score, $score_width, $self->score);

	print " " x $inner_padding;

	$self->draw_sub_score($best_score, $score_width, $self->best_score);

	say "";
}

sub draw_sub_score {
	my ($self, $string, $score_width, $score) = @_;
	printf "%s%*d", colored($string, "bold"), $score_width, $score;
}

sub tile_color {
	my ($self, $value) = @_;
	!defined $value  ? ""
	: $value < 4     ? "reverse cyan"
	: $value < 8     ? "reverse bright_blue"
	: $value < 16    ? "reverse blue"
	: $value < 32    ? "reverse green"
	: $value < 64    ? "reverse magenta"
	: $value < 128   ? "reverse bright_red"
	: $value < 4096  ? "reverse yellow"
	                 : "reverse";
}

sub board_width {
	my $self = shift;
	$self->size * CELL_WIDTH + BORDER_WIDTH * 2;
}

sub board_height {
	my $self = shift;
	$self->size * CELL_HEIGHT + BORDER_HEIGHT * 2;
}

sub draw_border_horizontal {
	my $self = shift;
	say colored(" " x $self->board_width, BORDER_COLOR);
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

sub restore_cursor {
	my $self = shift;
	printf "\e[%dA", $self->board_height + 1;
}

1;
