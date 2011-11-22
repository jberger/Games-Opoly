use MooseX::Declare;
use Method::Signatures::Modifiers;

class Opoly::Board::Group {

  use Opoly::Board::Tile;

  has 'name' => ( isa => 'Str', is => 'ro', required => 1 );
  has 'tiles' => ( isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub{ [] });

  method add_tile (Opoly::Board::Tile $tile) {
    push @{ $self->tiles }, $tile;
  }

}

class Opoly::Board::Group::Ownable
  extends Opoly::Board::Group {

  use List::MoreUtils qw/all uniq any/;

  has '+tiles' => (isa => 'ArrayRef[Opoly::Board::Tile::Ownable]');

  method monopoly () {
    my @tiles = @{ $self->tiles };

    # check that all tiles have owners
    return 0 unless all { $_->has_owner } @tiles;

    # check that all tiles have the same owner
    my @owners = uniq map { $_->owner } @tiles;
    return 0 unless ( 1 == @owners );

    # check that none are mortgaged
    return 0 if ( any { $_->mortgaged } @tiles );

    return $owners[0];
  }

  method number_owned_by ( Opoly::Player $player ) {
    my $num = grep { defined $_ and $_ == $player } map { $_->owner } @{ $self->tiles };

    return $num;
  }

}

class Opoly::Board::Group::Property 
  extends Opoly::Board::Group::Ownable {

  use Carp;
  use List::Util 'sum';

  has 'houses_cost' => ( isa => 'Num', is => 'ro', required => 1 );
  has '+tiles' => ( isa => 'ArrayRef[Opoly::Board::Tile::Property]');

  method houses_available () {
    return sum map { 5 - $_->houses } @{ $self->tiles };
  } 

  method buy_houses ( Num $number ) {
    my $houses_cost = $self->houses_cost;
    my @tiles = @{ $self->tiles };

    my $owner = $self->monopoly;
    unless ( $owner ) {
      carp "Zero or multiple owners found in group, buying houses not possible";
      return 0;
    }

    my $num_available = $self->houses_available;
    if ( $number > $num_available ) {
      carp "Too many houses requested, buying max ($num_available) instead";
      $number = $num_available;
    }

    my $num_each = int( $number / ( scalar @tiles ) );
    my $remaining = $number % scalar @tiles;

    my @tiles_houses = 
      map  { [$_, $num_each + ($remaining-- > 0)] } 
      sort {
        $a->houses	<=> $b->houses		||
        $b->rent->[0]	<=> $a->rent->[0]	||
        $b->address	<=> $a->address 
      } 
      @tiles;

    my $cost = sum map { $_->[1] * $houses_cost } @tiles_houses;

    if ( $owner->pay($cost) ) {
      map { 
        my ($tile, $num) = @$_;
        $tile->houses( $num + $tile->houses );
      } @tiles_houses;

      return 1;
    }

    return 0;
  }

}

