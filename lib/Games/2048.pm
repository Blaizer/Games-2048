=head1 NAME

Games::2048 - An ASCII clone of the 2048 game

=head1 SYNOPSIS

 use Games::2048;
 Games::2048->new->run;

=head1 DESCRIPTION

This module is a full clone of the L<2048 game by Gabriele Cirulli|http://gabrielecirulli.github.io/2048/>. It runs at the command-line, complete with controls identical to the original, a colorful interface, and even some text-based animations! It should work on Linux, Mac, and Windows.

Once installed, run the game with the command:

 2048

=head1 TODO

=over

=item * Add slide and merge animations

=item * Add button to toggle animations on/off

=item * Add buttons to zoom the board in and out

=item * Add colors for 256-color terminals

=item * Abstract input system to allow for AI or replay input

=item * Test on more systems and terminals

=back

=head1 AUTHOR

Blaise Roth <blaizer@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (C) 2014 by Blaise Roth.

This is free software; you can redistribute and/or modify it under
the same terms as the Perl 5 programming language system itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut

package Games::2048;
use 5.012;
use Moo;

our $VERSION = '0.06';

use Time::HiRes;

use constant {
	FRAME_TIME => 1/15,
};

use Games::2048::Input;
use Games::2048::Animation;
use Games::2048::Tile;
use Games::2048::Grid;
use Games::2048::Board;
use Games::2048::Game;

has size        => is => 'ro', default => 4;
has start_tiles => is => 'ro', default => 2;
has best_score  => is => 'rw', default => 0;

sub run {
	my $self = shift;

	my $quit;
	my $game;
	my $first_time = 1;
	Games::2048::Input::update_window_size;

	while (!$quit) {
		if ($first_time and $game = Games::2048::Game->restore) {
			$self->update_best_score($game);
			undef $game if $game->lose or !$game->is_valid;
		}
		else {
			undef $game;
		}
		if (!$game) {
			$game = Games::2048::Game->new(
				size => $self->size,
				best_score => $self->best_score,
			);

			$game->insert_start_tiles($self->start_tiles);
		}

		if ($first_time) {
			$first_time = 0;
			$game->draw_welcome;
		}

		RUN: $game->draw;

		my $restart;
		my $time = Time::HiRes::time;

		PLAY: while (1) {
			if (!$game->lose and !$game->win) {
				while (defined(my $key = Games::2048::Input::read_key)) {
					my $vec = Games::2048::Input::key_vector($key);
					if ($vec) {
						$game->move($vec);
					}
					elsif ($key =~ /^[q]$/i) {
						$quit = 1;
						last PLAY;
					}
					elsif ($key =~ /^[r]$/i) {
						$restart = 1;
						last PLAY;
					}
				}
			}

			$game->draw(1);

			if (!$game->needs_redraw and $game->lose || $game->win) {
				last PLAY;
			}

			my $new_time = Time::HiRes::time;
			my $delta_time = $new_time - $time;
			my $delay = FRAME_TIME - $delta_time;
			$time = $new_time;
			if ($delay > 0) {
				Time::HiRes::sleep($delay);
				$time += $delay;
			}
		}

		$game->draw_win;
		$self->update_best_score($game);

		if (!$quit and !$restart) {
			print $game->win ? "Keep going?" : "Try again?", " (Y/n) ";
			STDOUT->flush;
			{
				my $key = Games::2048::Input::poll_key;
				if ($key =~ /^[yn]$/i) {
					print $key;
				}
				if ($key =~ /^[nq]$/i) {
					$quit = 1;
				}
				elsif ($key =~ /^[yr\n]$/i) {
					say "";
				}
				else {
					redo;
				}
			}
		}
		say "";

		if ($game->win) {
			$game->win(0);
			goto RUN if !$quit;
		}
	}

	$game->save;
}

sub update_best_score {
	my ($self, $game) = @_;
	if (defined $game->best_score and $game->best_score > $self->best_score) {
		$self->best_score($game->best_score);
	}
	else {
		$game->best_score($self->best_score);
	}
}

1;
