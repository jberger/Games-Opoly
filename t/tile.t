use strict;
use warnings;

use Test::More;

use Games::Opoly::UI::Test;
use Games::Opoly::Player;
use Games::Opoly::Board::Group;

use_ok( 'Games::Opoly::Board::Tile' );

my $ui = Games::Opoly::UI::Test->new();
my $player = Games::Opoly::Player->new( name => 'John Doe', ui => $ui );

my $group = Games::Opoly::Board::Group->new( name => 'Test Group' );
my $tile = Games::Opoly::Board::Tile->new( name => 'Test Tile', group => $group, address => 1 );

isa_ok( $tile, 'Games::Opoly::Board::Tile' );
is( $group->tiles->[0], $tile, 'The tile object exists in the groups\'s tiles arrayref' );

$tile->arrive( $player );
is( $player->location, $tile, 'Player reports arriving at tile' );
is( $tile->occupants->[0], $player, 'Tile reports having player in its occupants arrayref' );

$tile->leave( $player );
ok( ! $player->location, 'After leave, player has no location' );
ok( ! @{ $tile->occupants }, '... and the tile has no occupants' );

done_testing;
