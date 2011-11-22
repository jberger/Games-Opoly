use strict;
use warnings;

use Test::More;

use Opoly::UI::Test;
use Opoly::Player;
use Opoly::Board::Group;

use_ok( 'Opoly::Board::Tile' );

my $ui = Opoly::UI::Test->new();
my $player = Opoly::Player->new( name => 'John Doe', ui => $ui );
my $money = $player->money;

my $houses_cost = 50;
my $group = Opoly::Board::Group::Property->new( 
  name => 'Test Group',
  houses_cost => $houses_cost,
);

my $price = 100;
my $rent = [20, 50, 100, 200, 300, 500];
my $tile = Opoly::Board::Tile::Property->new( 
  rent => $rent, 
  price => $price, 
  name => 'Test Tile', 
  group => $group, 
  address => 1,
);

isa_ok( $tile, 'Opoly::Board::Tile' );
isa_ok( $tile, 'Opoly::Board::Tile::Ownable' );
isa_ok( $tile, 'Opoly::Board::Tile::Property' );
is( $group->tiles->[0], $tile, 'The tile object exists in the groups\'s tiles arrayref' );
ok( ! $group->monopoly, 'Group is not a monopoly' );

$tile->arrive( $player );
is( $player->location, $tile, 'Player reports arriving at tile' );
is( $tile->occupants->[0], $player, 'Tile reports having player in its occupants arrayref' );
like( (grep { /^Buy/ } keys %{ $player->actions })[0], qr/^Buy/, 'Arrival at ownable tile adds buy action to player' );

$tile->leave( $player );
ok( ! $player->location, 'After leave, player has no location' );
ok( ! @{ $tile->occupants }, '... and the tile has no occupants' );
ok( ! (grep { /^Buy/ } keys %{ $player->actions }), 'Leaving ownable tile removes buy action from player' );

$tile->buy($player);
ok( $tile->has_owner, 'After purchase: tile reports having an owner' );
is( $tile->owner, $player, 'After purchase: owner is correct' );
ok( (grep {$_ == $tile} @{ $player->properties }), 'After purchase: player reports tile in properties' );
is( $player->money, $money-=$price, 'After purchase: player paid correct amount' );

# test some group stuff
is( $group->number_owned_by( $player ), 1, 'After purchase: group reports "one owned" by player' );
ok( $group->monopoly, 'After purchase: does constitute monopoly' );

is( $group->houses_available, 5, 'Before buying houses: 5 houses available' );
$group->buy_houses(2);
is( $group->houses_available, 3, 'After buying 2 houses: 3 houses available' );
is( $tile->houses, 2, 'After buying 2 houses, tile reports having 2 houses' );
is( $player->money, ($money-=2*$houses_cost), 'After buying houses, player cash is correct' );

# mortgaging
$tile->mortgage;


done_testing;


