use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::Board {

  use Games::Opoly::Board::Group;
  use Games::Opoly::Board::Tile;

  has 'groups' => (isa => 'ArrayRef[Games::Opoly::Board::Group]', is => 'ro', required => 1);
  has 'tiles' => (isa => 'ArrayRef', is => 'ro', required => 1);
  has 'num_tiles' => (isa => 'Num', is => 'ro', lazy => 1, builder => '_num_tiles');
  has 'start' => (isa => 'Games::Opoly::Board::Tile', is => 'ro', required => 1);
  has 'jail' => (isa => 'Games::Opoly::Board::Tile', is => 'ro', required => 1);


  method _num_tiles () {
    return scalar @{ $self->tiles };
  }

  method get_tile (Num $address) {
    return $self->tiles->[$address]
  }

  sub BUILD {
    my $self = shift;
    # Test for a valid board

    my $tiles = $self->tiles;

    my $i = 0; # expected address
    my $j = 0; # offset if tile is missing
    my @missing_tiles = 
      map {$_->[1] - 1} 
      grep { if ($_->[0] + $j == $_->[1]) { 0 } else {$j++; 1} } 
      map { [$i++, $_->address] } 
      @$tiles; 
    die "Board incomplete! Missing tiles " . join(', ', @missing_tiles) if @missing_tiles;

    # Populate Arrest Tiles with related Jail tiles
    map { $_->jail( $self->jail ) unless $_->jail } grep { $_->isa('Games::Opoly::Board::Tile::Arrest') } @$tiles;

  }

}

