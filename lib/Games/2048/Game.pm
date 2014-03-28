package Games::2048::Game;
use 5.01;
use Moo;

has grid         => is => 'lazy';
has size         => is => 'ro', default => 4;
has start_tiles  => is => 'ro', default => 2;
has score        => is => 'rw', default => 0;
has needs_redraw => is => 'rw', default => 1;

sub _build_grid {
	my $self = shift;
	Games::2048::Grid->new(size => $self->size);
}

sub run {

}

1;
