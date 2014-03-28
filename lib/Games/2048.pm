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

use Games::2048::Input;
use Games::2048::Tile;
use Games::2048::Grid;
use Games::2048::Game;

has size        => is => 'ro', default => 4;
has start_tiles => is => 'ro', default => 2;

sub run {
	my $self = shift;
	say "2048";
	say "Join the numbers and get to the 2048 tile!";
	say "HOW TO PLAY: Use your arrow keys to move the tiles. When two tiles with the\nsame number touch, they merge into one!";
	say "";

	my $quit = 0;
	while (!$quit) {
		my $game = Games::2048::Game->new(size => $self->size, start_tiles => $self->start_tiles);
		$game->run;

		$quit = $game->quit;

		if (!$quit) {
			print "Play again? (Y/n) ";
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
	}
}

1;
