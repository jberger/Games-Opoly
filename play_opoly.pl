#!/usr/bin/env perl

use strict;
use warnings;

use 5.10.0;

use Opoly;
use Opoly::Player;
use Opoly::Board;
use Opoly::Board::Group;
use Opoly::Board::Tile;
use Opoly::UI::CLI;

my $board_file = 'standard_board.conf';

my $board = do $board_file or die "Couldn't load board: $@, ";

my $game = Opoly->new( 
  board => $board, 
  ui => Opoly::UI::CLI->new(),
);

$game->add_player(
  Opoly::Player->new(name => 'Joel')
);
$game->add_player(
  Opoly::Player->new(name => 'Carolyn')
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
