use 5.010;
use strictures;
use Test::More;
use Games::2048;

my $game = Games::2048::Game->new;
my $small_game = Games::2048::Game->new(size => 2);
my $big_game = Games::2048::Game->new(size => 7);

isa_ok $game, "Games::2048::Grid", "game";
isa_ok $small_game, "Games::2048::Grid", "small_game";
isa_ok $big_game, "Games::2048::Grid", "big_game";

done_testing
