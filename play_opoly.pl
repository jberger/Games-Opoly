#!/usr/bin/env perl

use strict;
use warnings;

use 5.10.0;

use Opoly;
use Opoly::Board;
use Opoly::Board::Group;
use Opoly::Board::Tile;

my %groups = map { $_ => Opoly::Board::Group->new(name => $_) } qw(Corners);
my %tiles = (
  start => Opoly::Board::Tile->new(
    name => 'Start',
    address => 0,
    group => $groups{Corners},
  )
);

foreach my $group (keys %groups) {
  foreach my $tile (@{ $groups{$group}->tiles }) {
    say $tile->name;
  }
}
