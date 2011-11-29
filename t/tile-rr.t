use strict;
use warnings;

use Test::More;

use Games::Opoly::UI::Test;
use Games::Opoly::Player;
use Games::Opoly::Board::Group;

use_ok( 'Games::Opoly::Board::Tile' );

my $ui = Games::Opoly::UI::Test->new();
my $player = Games::Opoly::Player->new( name => 'John Doe', ui => $ui );
my $money = $player->money;

my $group = Games::Opoly::Board::Group::Ownable->new( name => 'Test Group' );

my $price = 50;
my $rr1 = Games::Opoly::Board::Tile::Railroad->new( 
  price   => $price,
  name    => 'rr1',
  group   => $group,
  address => 1,
);
my $rr2 = Games::Opoly::Board::Tile::Railroad->new( 
  price   => $price,
  name    => 'rr2',
  group   => $group,
  address => 2,
);

for my $rr ($rr1, $rr2) {
  isa_ok( $rr, 'Games::Opoly::Board::Tile::Railroad' );
  isa_ok( $rr, 'Games::Opoly::Board::Tile::Ownable'  );
}

$rr1->buy($player);

is( $rr1->owner, $player, 'After purchase, RR tile reports correct owner' );
is( $player->money, $money -= $price, 'After purchse, player money is correct' );
is( $rr1->get_rent, 25, 'One owned rent is default (25)' );

$rr2->buy($player);

is( $rr2->owner, $player, 'After purchase, RR tile reports correct owner' );
is( $player->money, $money -= $price, 'After purchse, player money is correct' );
is( $rr1->get_rent, 50, 'Two owned rent is doubled (50)' );
is( $rr2->get_rent, 50, 'Two owned rent is doubled (50)' );

done_testing;

