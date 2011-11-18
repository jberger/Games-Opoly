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

my $group = Opoly::Board::Group::Ownable->new( name => 'Test Group' );
my $price = 100;
my $tile = Opoly::Board::Tile::Ownable->new( price => $price, name => 'Test Tile', group => $group, address => 1 );

isa_ok( $tile, 'Opoly::Board::Tile' );
isa_ok( $tile, 'Opoly::Board::Tile::Ownable' );
is( $group->tiles->[0], $tile, 'The tile object exists in the groups\'s tiles arrayref' );
is( $group->monopoly, 0, 'Tile is not a monopoly' );

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


$tile->mortgage;
ok( $tile->mortgaged, 'After mortgage: tile reports that it is mortgaged' );

done_testing;


