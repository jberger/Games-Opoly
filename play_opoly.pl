#!/usr/bin/env perl

use strict;
use warnings;

use 5.10.0;

#use Opoly;
use Opoly::Board;
use Opoly::Board::Group;
use Opoly::Board::Tile;

my $board = do 'standard_board.conf';

my $groups = $board->groups;
foreach my $group (@$groups) {
  say $group->name, ":";
  foreach my $tile (@{ $group->tiles }) {
    say "\t", $tile->name;
  }
}
