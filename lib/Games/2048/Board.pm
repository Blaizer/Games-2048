package Games::2048::Board;
use 5.012;
use Moo;

use Text::Wrap;
use Term::ANSIColor;
use POSIX qw/floor ceil/;
use List::Util qw/max min/;
use Color::ANSI::Util qw/ansifg ansibg/;

extends 'Games::2048::Grid';

has score        => is => 'rw', default => 0;
has best_score   => is => 'rw', default => 0;
has needs_redraw => is => 'rw', default => 1;
has win          => is => 'rw', default => 0;
has lose         => is => 'rw', default => 0;

has moving     => is => 'rw';
has moving_vec => is => 'rw';

has border_width  => is => 'rw', default => 2;
has border_height => is => 'rw', default => 1;
has cell_width    => is => 'rw', default => 7;
has cell_height   => is => 'rw', default => 3;
has score_width   => is => 'rw', default => 7;

sub insert_tile {
	my ($self, $cell, $value) = @_;
	my $tile = Games::2048::Tile->new(
		value => $value,
		appear => Games::2048::Animation->new(
			duration => 0.2,
			first_value => -1 / max($self->cell_width, $self->cell_height),
			last_value => 1,
		),
	);
	$self->set_tile($cell, $tile);
}

sub draw {
	my ($self, $redraw) = @_;

	return if $redraw and !$self->needs_redraw;

	$self->hide_cursor;
	$self->restore_cursor if $redraw;
	$self->needs_redraw(0);

	$self->draw_score;
	$self->draw_border_horizontal;

	for my $y (0..$self->size-1) {
		for my $line (0..$self->cell_height-1) {
			$self->draw_border_vertical;

			for my $x (0..$self->size-1) {
				my $tile = $self->tile([$x, $y]);

				my $string;
				my $value = $tile ? $tile->value : undef;
				my $color = $self->tile_color($value);
				my $bgcolor = $self->tile_color(undef);

				my $lines = min(ceil(length($value // '') / $self->cell_width), $self->cell_height);
				my $first_line = floor(($self->cell_height - $lines) / 2);
				my $this_line = $line - $first_line;

				if ($this_line >= 0 and $this_line < $lines) {
					my $cols = min(ceil(length($value) / $lines), $self->cell_width);
					my $string_offset = $this_line * $cols;
					my $string_length = min($cols, length($value) - $string_offset, $self->cell_width);
					my $cell_offset = floor(($self->cell_width - $string_length) / 2);

					$string = " " x $cell_offset;

					$string .= substr($value, $string_offset, $string_length);

					$string .= " " x ($self->cell_width - $cell_offset - $string_length);
				}
				else {
					$string = " " x $self->cell_width;
				}

				if ($tile and $tile->appear) {
					# if any animation is going we need to keep redrawing
					$self->needs_redraw(1);

					my $value = $tile->appear->value;
					if ($line == $self->cell_height-1) {
						$tile->appear(undef) if !$tile->appear->update;
					}

					my $x_center = ($self->cell_width  - 1) / 2;
					my $y_center = ($self->cell_height - 1) / 2;

					my $on = 0;
					my $extra = 0;
					for my $col (0..$self->cell_width-1) {
						my $x_distance = $col  / $x_center - 1;
						my $y_distance = $line / $y_center - 1;
						my $distance = $x_distance**2 + $y_distance**2;

						my $within = $distance <= 2 * $value**2;

						if ($within xor $on) {
							$on = $within;

							my $insert = $on
								? $color
								: $bgcolor;

							substr($string, $col + $extra, 0) = $insert;
							$extra += length($insert);
						}
					}
					if ($on) {
						$string .= $bgcolor;
					}
				}
				else {
					$string = $color . $string . $bgcolor;
				}

				print $string;
			}

			$self->draw_border_vertical;
			say color("reset");
		}
	}

	$self->draw_border_horizontal;
	$self->show_cursor if !$self->needs_redraw;
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
	my $best_score = "Best:";

	my $blank_width = $self->board_width - length($score) - length($best_score);
	my $score_width = min(floor(($blank_width - 1) / 2), $self->score_width);
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
    if ($ENV{KONSOLE_DBUS_SERVICE}) {
        return
		!defined $value    ? ansifg("BBADA0") . ansibg("CCC0B3")
		: $value < 4       ? ansifg("776E65") . ansibg("EEE4DA")
		: $value < 8       ? ansifg("776E65") . ansibg("EDE0C8")
		: $value < 16      ? ansifg("F9F6F2") . ansibg("F2B179")
		: $value < 32      ? ansifg("F9F6F2") . ansibg("F59563")
		: $value < 64      ? ansifg("F9F6F2") . ansibg("F67C5F")
		: $value < 128     ? ansifg("F9F6F2") . ansibg("F65E3B")
		: $value < 256     ? ansifg("F9F6F2") . ansibg("EDCF72") . color("bold")
		: $value < 512     ? ansifg("F9F6F2") . ansibg("EDCC61") . color("bold")
		: $value < 1024    ? ansifg("F9F6F2") . ansibg("EDC850") . color("bold")
		: $value < 2048    ? ansifg("F9F6F2") . ansibg("EDC53F") . color("bold")
		: $value < 4096    ? ansifg("F9F6F2") . ansibg("EDC22E") . color("bold")
		                   : ansifg("F9F6F2") . ansibg("3C3A32") . color("bold");
	}
	my $bright = $^O eq "MSWin32" ? "underline " : "bright_";
	my $bold   = $^O eq "MSWin32" ? "underline"  : "bold";
	return color (
		!defined $value    ? "reset"
		: $value < 4       ? "reverse cyan"
		: $value < 8       ? "reverse ${bright}blue"
		: $value < 16      ? "reverse blue"
		: $value < 32      ? "reverse green"
		: $value < 64      ? "reverse magenta"
		: $value < 128     ? "reverse red"
		: $value < 4096    ? "reverse yellow"
		                   : "reverse $bold"
	);
}

sub border_color {
	$ENV{KONSOLE_DBUS_SERVICE}
		? ansifg("CCC0B3") . ansibg("BBADA0")
		: color("reverse");
}

sub board_width {
	my $self = shift;
	return $self->size * $self->cell_width + $self->border_width * 2;
}

sub board_height {
	my $self = shift;
	return $self->size * $self->cell_height + $self->border_height * 2;
}

sub draw_border_horizontal {
	my $self = shift;
	say $self->border_color, " " x $self->board_width, color("reset") for 1..$self->border_height;
}
sub draw_border_vertical {
	my $self = shift;
	print $self->border_color, " " x $self->border_width, $self->tile_color(undef);
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

sub hide_cursor {
	my $self = shift;
	state $once = eval 'END { $self->show_cursor }';
	print "\e[?25l";
}
sub show_cursor {
	my $self = shift;
	print "\e[?25h";
}

1;
