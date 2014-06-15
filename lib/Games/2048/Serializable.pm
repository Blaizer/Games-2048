package Games::2048::Serializable;
use 5.012;
use Moo::Role;

# increment this whenever we break compat with older game objects
our $VERSION = '0.03';

use Storable;
use File::Spec::Functions;
use File::HomeDir;

sub _game_file {
	state $dir = eval {
		my $my_dist_method = "my_dist_" . ($^O eq "MSWin32" ? "data" : "config");
		File::HomeDir->$my_dist_method("Games-2048", {create => 1});
	};
	return if !defined $dir;
	return catfile($dir, "game.dat");
}

sub save {
	my $self = shift;
	$self->version(__PACKAGE__->VERSION);
	eval { store($self, _game_file); 1 };
}

sub restore {
	my $self = eval { retrieve(_game_file) };
	$self;
}

sub is_valid {
	my $self = shift;
	defined $self->version and $self->version >= __PACKAGE__->VERSION;
}
