#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use 5.10.0;

use Games::Opoly;
use Games::Opoly::Player;
use Games::Opoly::Board;
use Games::Opoly::Board::Group;
use Games::Opoly::Board::Tile;
use Games::Opoly::UI::CLI;

use Games::Opoly::Collections::Boards::Standard;

use Getopt::Long;
my $loaded_dice = 0;
GetOptions(
  "loaded" => \$loaded_dice,
);

my $board_file = 'standard_board.conf';

my $board = Games::Opoly::Collections::Boards::Standard->board();

my $game = Games::Opoly->new( 
  board => $board, 
  ui => Games::Opoly::UI::CLI->new(),
  "loaded_dice" => $loaded_dice,
);

$game->add_player(
  Games::Opoly::Player->new(
    name => 'Joel', 
    ui => $game->ui,
  )
);
$game->add_player(
  Games::Opoly::Player->new(
    name => 'Carolyn',
    ui => $game->ui,
  )
);

$game->play_game();

__END__

my $groups = $board->groups;
foreach my $group (@$groups) {
  say $group->name, ":";
  foreach my $tile (@{ $group->tiles }) {
    say "\t", $tile->name;
  }
}
