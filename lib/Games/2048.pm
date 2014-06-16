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
use mro;

our $VERSION = '0.08';

use constant FRAME_TIME => 1/15;

use Games::2048::Util;
use Games::2048::Serializable;
use Games::2048::Animation;
use Games::2048::Tile;
use Games::2048::Grid;
use Games::2048::Board;
use Games::2048::Game;
use Games::2048::Game::Input;

has game       => is => 'rw';
has game_class => is => 'rw', default => 'Games::2048::Game::Input';
has game_file  => is => 'rw', default => 'game.dat';

has quit    => is => 'rw', default => 0;
has restart => is => 'rw', default => 0;

has size        => is => 'ro', default => 4;
has start_tiles => is => 'ro', default => 2;
has best_score  => is => 'rw', default => 0;

has no_frame_delay  => is => 'rw', default => 0;
has no_animations   => is => 'rw', default => 0, trigger => 1;
has no_restore_game => is => 'rw', default => 0;
has no_save_game    => is => 'rw', default => 0;

sub run {
	my $self = shift;

	$self->quit(0);
	my $first_time = 1;
	Games::2048::Util::update_window_size;

	while (!$self->quit) {
		$self->game(undef);
		$self->restore_game if $first_time;
		$self->game(undef) if $self->no_restore_game;
		$self->new_game if !$self->game;

		if ($first_time) {
			$first_time = 0;
			$self->game->draw_welcome;
		}

		KEEP_GOING: $self->game->draw;

		$self->restart(0);

		# initialize the frame delay
		Games::2048::Util::frame_delay if !$self->no_frame_delay;

		while (1) {
			unless ($self->game->lose || $self->game->win) {
				$self->game->handle_input($self);
			}

			$self->game->draw(1);

			if ($self->quit or $self->restart
				or $self->game->lose || $self->game->win and !$self->game->needs_redraw
			) {
				last;
			}

			Games::2048::Util::frame_delay(FRAME_TIME) if !$self->no_frame_delay;
		}

		$self->game->draw_win;
		$self->update_best_score;
		$self->save_game if !$self->no_save_game and $self->game->lose;

		if (!$self->quit and !$self->restart) {
			print $self->game->win ? "Keep going?" : "Try again?", " (Y/n) ";
			STDOUT->flush;
			$self->game->handle_finish($self);

			if ($self->quit) {
				print "n";
			}
			else {
				say "y";
			}
		}
		say "";

		if ($self->game->win) {
			$self->game->win(0);
			goto KEEP_GOING if !$self->quit;
		}
	}

	$self->save_game if !$self->no_save_game;
}

sub move {
	my ($self, $vec) = @_;
	$self->game->move($vec);
}

sub new_game {
	my $self = shift;

	my $game_class = $self->game_class;
	$self->game($game_class->new(
		size => $self->size,
		best_score => $self->best_score,
		no_animations => $self->no_animations,
	));

	$self->game->insert_start_tiles($self->start_tiles);
}

sub restore_game {
	my $self = shift;

	my $game_class = $self->game_class;
	$self->game($game_class->restore($self->game_file));
	if ($self->game) {
		$self->update;
		$self->game(undef) if $self->game->lose or !$self->game->is_valid;
	}
}

sub save_game {
	my $self = shift;
	$self->game->save($self->game_file);
}

sub update {
	my $self = shift;
	$self->no_animations($self->game->no_animations);
	$self->update_best_score;
}

sub update_best_score {
	my $self = shift;
	my $game = $self->game;
	if (defined $game->best_score and $game->best_score > $self->best_score) {
		$self->best_score($game->best_score);
	}
	else {
		$game->best_score($self->best_score);
	}
}

sub _trigger_no_animations {
	my ($self, $no_anim) = @_;
	$self->game->no_animations($no_anim);
	$self->game->reset_animations if $no_anim;
}

1;
