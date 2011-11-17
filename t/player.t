use strict;
use warnings;

use Test::More;
use Opoly::UI::Test;

## N.B. some of the player object testing happens in t/tile.t

my $ui = Opoly::UI::Test->new;

use_ok('Opoly::Player');

my $player = Opoly::Player->new(name => 'John Doe', ui => $ui);
isa_ok( $player, 'Opoly::Player');


my $money = $player->money;
$player->collect( 100 );
is( $player->money, $money+=100, 'collect adds to money property' );

is( $player->pay( 100 ), 1, 'pay returns 1 on success' );
is( $player->money, $money-=100, 'pay subtracts from money' );
is( $player->must_pay( 100 ), 1, 'must_pay returns 1 on success' );
is( $player->money, $money-=100, 'must_pay subtracts from money' );

# test fail states
is( $player->pay( 1000000 ), 0, 'pay returns 0 on failure' );
is( $player->money, $money, 'pay failure does not remove any money' );



done_testing;

