package Games::2048::Board;
use 5.01;
use Moo;

use Text::Wrap;
use Term::ANSIColor;
use POSIX qw/floor ceil/;
use List::Util qw/max min/;

extends 'Games::2048::Grid';

has score        => is => 'rw', default => 0;
has best_score   => is => 'rw', default => 0;
has needs_redraw => is => 'rw', default => 1;
has win          => is => 'rw', default => 0;
has lose         => is => 'rw', default => 0;

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

sub insert_tile {
	my ($self, $cell, $value) = @_;
	my $tile = Games::2048::Tile->new(
		value => $value,
		appear => Games::2048::Animation->new(
			duration => 0.2,
			first_value => -1 / max(CELL_WIDTH, CELL_HEIGHT),
			last_value => 1,
		),
	);
	$self->set_tile($cell, $tile);
}

sub draw {
	my ($self, $redraw) = @_;

	return if $redraw and !$self->needs_redraw;
	$self->restore_cursor if $redraw;
	$self->needs_redraw(0);

	$self->draw_score;
	$self->draw_border_horizontal;

	for my $y (0..$self->size-1) {
		for my $line (0..CELL_HEIGHT-1) {
			$self->draw_border_vertical;

			for my $x (0..$self->size-1) {
				my $tile = $self->tile([$x, $y]);

				my $string;
				my $color;

				if (defined $tile) {
					my $value = $tile->value;
					$color = $self->tile_color($value);

					my $lines = min(ceil(length($value) / CELL_WIDTH), CELL_HEIGHT);
					my $first_line = floor((CELL_HEIGHT - $lines) / 2);
					my $this_line = $line - $first_line;

					if ($this_line >= 0 and $this_line < $lines) {
						my $cols = min(ceil(length($value) / $lines), CELL_WIDTH);
						my $string_offset = $this_line * $cols;
						my $string_length = min($cols, length($value) - $string_offset, CELL_WIDTH);
						my $cell_offset = floor((CELL_WIDTH - $string_length) / 2);

						$string = " " x $cell_offset;

						$string .= substr($value, $string_offset, $string_length);

						$string .= " " x (CELL_WIDTH - $cell_offset - $string_length);
					}
					else {
						$string = " " x CELL_WIDTH;
					}

					if ($tile->appear) {
						# if any animation is going we need to keep redrawing
						$self->needs_redraw(1);

						my $value = $tile->appear->value;
						if ($line == CELL_HEIGHT-1) {
							$tile->appear(undef) if !$tile->appear->update;
						}

						my $x_center = (CELL_WIDTH  - 1) / 2;
						my $y_center = (CELL_HEIGHT - 1) / 2;

						my $on = 0;
						my $extra = 0;
						for my $col (0..CELL_WIDTH-1) {
							my $x_distance = $col  / $x_center - 1;
							my $y_distance = $line / $y_center - 1;
							my $distance = $x_distance**2 + $y_distance**2;

							my $within = $distance <= 2 * $value**2;

							if ($within xor $on) {
								$on = $within;

								my $insert = $on
									? color($color)
									: color("reset");

								substr($string, $col + $extra, 0) = $insert;
								$extra += length($insert);
							}
						}
						if ($on) {
							$string .= color("reset");
						}
					}
					else {
						$string = colored($string, $color);
					}

					print $string;
				}
				else {
					print " " x CELL_WIDTH;
				}
			}

			$self->draw_border_vertical;
			say "";
		}
	}

	$self->draw_border_horizontal;
}

sub draw_win {
	my $self = shift;
	return if !$self->win and !$self->lose;
	my $message =
		$self->win ? "You win!"
		           : "Game over!";
	my $offset = ceil(($self->board_width - length($message)) / 2);

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
	my $bright = $^O eq "MSWin32" ? "bold " : "bright_";
	!defined $value    ? ""
	: $value < 4       ? "reverse cyan"
	: $value < 8       ? "reverse ${bright}blue"
	: $value < 16      ? "reverse blue"
	: $value < 32      ? "reverse green"
	: $value < 64      ? "reverse magenta"
	: $value < 128     ? "reverse red"
	: $value < 4096    ? "reverse yellow"
	                   : "reverse bold";
}

sub board_width {
	my $self = shift;
	return $self->size * CELL_WIDTH + BORDER_WIDTH * 2;
}

sub board_height {
	my $self = shift;
	return $self->size * CELL_HEIGHT + BORDER_HEIGHT * 2;
}

sub draw_border_horizontal {
	my $self = shift;
	say colored(" " x $self->board_width, BORDER_COLOR);
}
sub draw_border_vertical {
	print colored("  ", BORDER_COLOR)
}

sub restore_cursor {
	my $self = shift;
	printf "\e[%dA", $self->board_height + 1;
}

sub draw_welcome {
	local $Text::Wrap::columns = Games::2048::Input::window_size;

	my $message = <<MESSAGE;
2048 - Join the numbers and get to the 2048 tile!

How to play: Use your arrow keys to move the tiles. When two tiles with the same number touch, they merge into one!
Quit: Q
New Game: R

MESSAGE

	$message = wrap "", "", $message;

	$message =~ s/(^2048|How to play:|arrow keys|merge into one!|Quit:|New Game:)/colored $1, "bold"/ge;

	say $message;
}

1;
