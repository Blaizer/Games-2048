package Games::2048::Tile;
use 5.012;
use Moo;

has value  => is => 'rw', default => 2;
has merged => is => 'rw', default => 0;
has appear => is => 'rw';

has merging_tiles => is => 'rw';
has moving_from   => is => 'rw';

1;
