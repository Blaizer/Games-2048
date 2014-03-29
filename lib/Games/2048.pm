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

use Games::2048::Input;
use Games::2048::Tile;
use Games::2048::Grid;
use Games::2048::Game;

has size        => is => 'ro', default => 4;
has start_tiles => is => 'ro', default => 2;
has best_score  => is => 'rw', default => 0;

sub run {
	my $self = shift;
	say "2048";
	say "Join the numbers and get to the 2048 tile!";
	say "HOW TO PLAY: Use your arrow keys to move the tiles. When two tiles with the\nsame number touch, they merge into one!";
	say "";

	my $quit = 0;
	my $game;
	my $first_time = 1;

	while (!$quit) {
		if ($first_time) {
			$first_time = 0;
			$game = $self->restore_game;
			$self->best_score($game->best_score);
			undef $game if $game->lose;
		}
		else {
			undef $game;
		}
		if (!$game) {
			$game = Games::2048::Game->new(
				size => $self->size,
				best_score => $self->best_score,
			);

			$game->insert_random_tile for 1..$self->start_tiles;
		}

		RUN: $game->run;

		$self->best_score($game->best_score) if $game->best_score > $self->best_score;

		$quit = $game->quit;
		if (!$quit and !$game->restart) {
			print $game->win ? "Keep playing?" : "Play again?", " (Y/n) ";
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
			say "";
		}

		if ($game->restart) {
			$game->restart(0);
			say "";
		}
		if ($game->win) {
			$game->win(0);
			goto RUN if !$quit;
		}
	}

	$game->quit(0);
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
