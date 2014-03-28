package Games::2048;

use 5.01;
use strict;
use warnings;

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

our $VERSION = '0.01';

use Games::2048::Grid;
use Games::2048::Tile;

1;
