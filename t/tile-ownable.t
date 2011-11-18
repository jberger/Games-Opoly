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
my $action_tile = Opoly::Board::Tile::Ownable->new( price => $price, name => 'Test Tile', group => $group, address => 2 );

isa_ok( $tile, 'Opoly::Board::Tile' );
isa_ok( $tile, 'Opoly::Board::Tile::Ownable' );
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
ok( ! $group->monopoly, 'After purchase: does not constitute monopoly' );

# buy $action_tile by action
$action_tile->arrive( $player );
my ($buy) = grep { /^Buy/ } keys %{ $player->actions };
ok( $buy, 'Has buy action' );
$player->actions->{$buy}->();
is( $action_tile->owner, $player, 'After purchase: owner is correct' );
is( $player->money, $money-=$price, 'After purchase: player paid correct amount' );
ok( ! (grep { /^Buy/ } keys %{ $player->actions }), 'After purchase ownable tile removes buy action from player' );

# test some group stuff
is( $group->number_owned_by( $player ), 2, 'After purchase: group reports "two owned" by player' );
ok( $group->monopoly, 'After purchase: constitutes monopoly' );

# mortgaging
$tile->mortgage;
ok( $tile->mortgaged, 'After mortgage: tile reports that it is mortgaged' );
ok( ! $group->monopoly, 'After mortgage: group is not a monopoly' );
is( $player->money, $money+=$price/2, 'Mortgage returns money to the owner' );

$tile->unmortgage;
ok( ! $tile->mortgaged, 'After unmortgage: tile reports that it is not mortgaged' );
ok( $group->monopoly, 'After unmortgage: group is a monopoly' );
is( $player->money, $money-=1.1*$price/2, 'Unmortgage removes money from the owner' );

done_testing;


