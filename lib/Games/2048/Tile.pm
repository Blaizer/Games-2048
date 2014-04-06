package Games::2048::Tile;
use 5.012;
use Moo;

has value  => is => 'rw', default => 2;
has merged => is => 'rw', default => 0;
has appear => is => 'rw';

sub merge {
	my ($self, $tile) = @_;
	$self->value($self->value + $tile->value);
	$self->merged(1);
	$self->appear($tile->appear) if !$self->appear;
}

1;
