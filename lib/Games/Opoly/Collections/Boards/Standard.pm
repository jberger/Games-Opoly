use strict;
use warnings;

package Games::Opoly::Collections::Boards::Standard;

# Use Games::Opoly::Collections::Boards::Standard->board to get a populated board object

# Definitions of groups and tiles to compose board 

use Games::Opoly::Board;
use Games::Opoly::Board::Group;
use Games::Opoly::Board::Tile;

use Games::Opoly::Collections::Decks::Standard;

my %groups = (
  ( map { $_ => Games::Opoly::Board::Group->new(name => $_) } qw(Corners Cards Taxes) ),
  ( map { $_ => Games::Opoly::Board::Group::Ownable->new(name => $_) } qw(Railroads Utilities) ),
  ( map { $_->[0] => Games::Opoly::Board::Group::Property->new(name => $_->[0], houses_cost => $_->[1]) }
    ( [ Purple		=> 50  ],
      [ LightBlue	=> 50  ], 
      [ Magenta 	=> 100 ], 
      [ Orange		=> 100 ],
      [ Red 		=> 150 ],
      [ Yellow		=> 150 ],
      [ Green		=> 200 ],
      [ Blue		=> 200 ], ) 
  ),
);

my @tiles = (
  Games::Opoly::Board::Tile->new(
    name => 'Start',
    address => 0,
    group => $groups{Corners},
  ),
  Games::Opoly::Board::Tile->new(
    name => 'Jail',
    address => 10,
    group => $groups{Corners},
  ),
  Games::Opoly::Board::Tile->new(
    name => 'Free Parking',
    address => 20,
    group => $groups{Corners},
  ),
  Games::Opoly::Board::Tile::Arrest->new(
    name => 'Go To Jail',
    address => 30,
    group => $groups{Corners},
  ),

  Games::Opoly::Board::Tile::Property->new(
    name => 'Mediterranean Avenue',
    address => 1,
    group => $groups{Purple},
    price => 60,
    rent => [2,10,30,90,160,250],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Baltic Avenue',
    address => 3,
    group => $groups{Purple},
    price => 60,
    rent => [4,20,60,180,320,450],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Oriental Avenue',
    address => 6,
    group => $groups{LightBlue},
    price => 100,
    rent => [6,30,90,270,400,550],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Vermont Avenue',
    address => 8,
    group => $groups{LightBlue},
    price => 100,
    rent => [6,30,90,270,400,550],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Connecticut Avenue',
    address => 9,
    group => $groups{LightBlue},
    price => 120,
    rent => [8,40,100,300,450,600],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'St. Charles Place',
    address => 11,
    group => $groups{Magenta},
    price => 140,
    rent => [10,50,150,450,625,750],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'States Avenue',
    address => 13,
    group => $groups{Magenta},
    price => 140,
    rent => [10,50,150,450,625,750],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Virginia Avenue',
    address => 14,
    group => $groups{Magenta},
    price => 160,
    rent => [12,60,180,500,700,900],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'St. James Place',
    address => 16,
    group => $groups{Orange},
    price => 180,
    rent => [14,70,200,550,750,950],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Tennessee Avenue',
    address => 18,
    group => $groups{Orange},
    price => 180,
    rent => [14,70,200,550,750,950],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'New York Avenue',
    address => 19,
    group => $groups{Orange},
    price => 200,
    rent => [16,80,220,600,800,1000],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Kentucky Avenue',
    address => 21,
    group => $groups{Red},
    price => 220,
    rent => [18,90,250,700,875,1050],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Indiana Avenue',
    address => 23,
    group => $groups{Red},
    price => 220,
    rent => [18,90,250,700,875,1050],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Illinois Avenue',
    address => 24,
    group => $groups{Red},
    price => 240,
    rent => [20,100,300,750,925,1100],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Atlanic Avenue',
    address => 26,
    group => $groups{Yellow},
    price => 260,
    rent => [22,110,330,800,975,1150],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Ventnor Avenue',
    address => 27,
    group => $groups{Yellow},
    price => 260,
    rent => [22,110,330,800,975,1150],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Marvin Gardens',
    address => 29,
    group => $groups{Yellow},
    price => 280,
    rent => [24,120,360,850,1025,1200],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Pacific Avenue',
    address => 31,
    group => $groups{Green},
    price => 300,
    rent => [26,130,390,900,1100,1275],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'North Carolina Avenue',
    address => 32,
    group => $groups{Green},
    price => 300,
    rent => [26,130,390,900,1100,1275],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Pennsylvania Avenue',
    address => 34,
    group => $groups{Green},
    price => 320,
    rent => [28,150,450,1000,1200,1400],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Park Place',
    address => 37,
    group => $groups{Blue},
    price => 350,
    rent => [35,175,500,1100,1300,1500],
  ),
  Games::Opoly::Board::Tile::Property->new(
    name => 'Boardwalk',
    address => 39,
    group => $groups{Blue},
    price => 400,
    rent => [50,200,600,1400,1700,2000],
  ),

  Games::Opoly::Board::Tile::Railroad->new(
    name => 'Reading Railroad',
    address => 5,
    group => $groups{Railroads},
    price => 200,
  ),
  Games::Opoly::Board::Tile::Railroad->new(
    name => 'Pennsylvania Railroad',
    address => 15,
    group => $groups{Railroads},
    price => 200,
  ),
  Games::Opoly::Board::Tile::Railroad->new(
    name => 'B&0 Railroad',
    address => 25,
    group => $groups{Railroads},
    price => 200,
  ),
  Games::Opoly::Board::Tile::Railroad->new(
    name => 'Short Line',
    address => 35,
    group => $groups{Railroads},
    price => 200,
  ),

  Games::Opoly::Board::Tile::Utility->new(
    name => 'Electric Company',
    address => 12,
    group => $groups{Utilities},
    price => 150,
  ),
  Games::Opoly::Board::Tile::Utility->new(
    name => 'Water Works',
    address => 28,
    group => $groups{Utilities},
    price => 150,
  ),

  Games::Opoly::Board::Tile::Tax->new(
    name => 'Income Tax',
    address => 4,
    group => $groups{Taxes},
    amount => 200,
    percent => 10,
  ),
  Games::Opoly::Board::Tile::Tax->new(
    name => 'Luxury Tax',
    address => 38,
    group => $groups{Taxes},
    amount => 75,
  ),
);

my $deck = Games::Opoly::Collections::Decks::Standard->deck();

push @tiles, map { 
  Games::Opoly::Board::Tile::Card->new(
    name => 'Chance',
    address => $_,
    group => $groups{Cards},
    deck => $deck,
  ) 
} qw(7 22 36);

push @tiles, map { 
  Games::Opoly::Board::Tile::Card->new(
    name => 'Community Chest',
    address => $_,
    group => $groups{Cards},
    deck => $deck,
  ) 
} qw(2 17 33);

# Create and return board object

#TODO implement better ordering for finding duplicated/missed addresses
#my @ordered_tiles;

my $board = Games::Opoly::Board->new(
  groups => [ values %groups ],
  tiles  => [ sort { $a->address <=> $b->address } @tiles ],
  start  => ( grep { $_->name eq 'Start' } @tiles ),
  jail   => ( grep { $_->name eq 'Jail' } @tiles ),
);

sub board {
  return $board;
}


