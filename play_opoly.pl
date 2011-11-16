#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use 5.10.0;

use Opoly;
use Opoly::Player;
use Opoly::Board;
use Opoly::Board::Group;
use Opoly::Board::Tile;
use Opoly::UI::CLI;

use Opoly::Collections::Boards::Standard;

use Getopt::Long;
my $loaded_dice = 0;
GetOptions(
  "loaded" => \$loaded_dice,
);

my $board_file = 'standard_board.conf';

my $board = Opoly::Collections::Boards::Standard->board();

my $game = Opoly->new( 
  board => $board, 
  ui => Opoly::UI::CLI->new(),
  "loaded_dice" => $loaded_dice,
);

$game->add_player(
  Opoly::Player->new(
    name => 'Joel', 
    ui => $game->ui,
  )
);
$game->add_player(
  Opoly::Player->new(
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
