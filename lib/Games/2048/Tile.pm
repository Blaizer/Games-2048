package Games::2048::Tile;
use 5.01;
use Moo;

has value  => is => 'rw', default => 2;
has merged => is => 'rw', default => 0;

1;
