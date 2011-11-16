use strict;
use warnings;

use Test::More;
use Test::MockObject;

my $mock_ui = Test::MockObject->new();
$mock_ui->set_isa('Opoly::UI');

use_ok('Opoly::Player');

my $player = Opoly::Player->new(name => 'John Doe', ui => $mock_ui);
isa_ok( $player, 'Opoly::Player');


done_testing;

