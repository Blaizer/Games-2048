package Games::2048::Grid;
use 5.01;
use Moo;

has size  => is => 'ro', default => 4;
has cells => is => 'lazy';

sub _build_cells {
	my $self = shift;
	[ map [ (undef) x $self->size ], 1..$self->size ];
}

sub clear {
	my $self = shift;
	for ($self->each_cell) {
		my ($x, $y) = @$_;
		$self->cells->[$y][$x] = undef;
	}
}

sub each_cell {
	my $self = shift;
	map {
		my $y = $_;
		map $self->_cell_info($_, $y), 0..$self->size-1;
	} 0..$self->size-1;
}

sub available_cells {
	my $self = shift;
	my @cells;
	for ($self->each_cell) {
		my ($x, $y, $tile) = @$_;
		push @cells, $self->_cell_info($x, $y) if !$tile;
	};
	@cells;
}

sub has_available_cells {
	my $self = shift;
	!!scalar $self->available_cells;
}

sub within_bounds {
	my ($self, $cell) = @_;
	$cell->[0] >= 0 and $cell->[0] < $self->size and
	$cell->[1] >= 0 and $cell->[1] < $self->size;
}

sub tile {
	my ($self, $cell) = @_;
	return if !$self->within_bounds($cell);
	$self->cells->[$cell->[1]][$cell->[0]];
}

sub clear_tile {
	my ($self, $cell) = @_;
	$self->cells->[$cell->[1]][$cell->[0]] = undef;
}

sub set_tile {
	my ($self, $cell, $tile) = @_;
	$self->cells->[$cell->[1]][$cell->[0]] = $tile;
}

sub _cell_info {
	my ($self, $x, $y) = @_;
	[ $x, $y, $self->cells->[$y][$x] ];
}

1;
