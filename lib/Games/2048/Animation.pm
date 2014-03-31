package Games::2048::Animation;
use 5.01;
use Moo;

use POSIX qw/floor ceil/;
use Carp qw/croak/;

has cur_frame => is => 'rw', default => 0;
has duration  => is => 'rw', default => 0;

sub value {
	my $self = shift;
	my $cur_frame = $self->cur_frame;
	my $frame_count = $self->frame_count;
	return if $cur_frame >= $frame_count;
	$self->cur_frame($cur_frame + 1);
	return $cur_frame / ($frame_count - 1);
}

sub frame_count {
	my $self = shift;
	return floor($self->duration / Games::2048::FRAME_TIME);
}

1;
