=head1 NAME

Games::2048 - Clone of a clone of the 2048 game

=head1 SYNOPSIS

 use Games::2048;
 Games::2048->new->run;

=head1 AUTHOR

Blaise Roth <blaizer@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2014 by Blaise Roth.

This is free software; you can redistribute and/or modify it under
the same terms as the Perl 5 programming language system itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut

package Games::2048;
use 5.01;
use Moo;

our $VERSION = '0.01';

use Storable;
use File::ShareDir;
use File::Spec::Functions;
use Time::HiRes;

use constant {
	FRAME_TIME => 1/60,
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

	while (!$quit) {
		if ($first_time) {
			$game = $self->restore_game;
			if ($game) {
				$self->best_score($game->best_score);
				undef $game if $game->lose;
			}
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
			while (defined(my $key = Games::2048::Input::read_key)) {
				my $vec = Games::2048::Input::key_vector($key);
				if ($vec) {
					$game->move($vec);
				}
				elsif ($key =~ /^[q\e\cC]$/i) {
					$quit = 1;
					last PLAY;
				}
				elsif ($key =~ /^[r]$/i) {
					$restart = 1;
					last PLAY;
				}
			}

			$game->draw(1);

			if ($game->lose or $game->win) {
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

		$self->best_score($game->best_score) if $game->best_score > $self->best_score;

		if (!$quit and !$restart) {
			print $game->win ? "Keep going?" : "Try again?", " (Y/n) ";
			{
				my $key = Games::2048::Input::poll_key;
				if ($key =~ /^[ynq ]$/i) {
					print $key;
				}
				if ($key =~ /^[nq\e\cC]$/i) {
					$quit = 1;
				}
				elsif ($key =~ /^[y\r\n ]$/i) {
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

	$self->save_game($game);
}

sub save_game {
	my ($self, $game) = @_;
	eval { store($game, $self->game_file); 1 };
}

sub restore_game {
	my $self = shift;
	my $game = eval { retrieve $self->game_file };
}

sub game_file {
	my $self = shift;
	my $dir = eval { File::ShareDir::dist_dir("Games-2048") };
	return if !defined $dir;
	catfile $dir, "game.dat";
}

1;
