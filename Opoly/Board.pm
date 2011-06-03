use MooseX::Declare;

class Opoly::Board {

  use Opoly::Board::Group;
  use Opoly::Board::Tile;

  has 'groups' => (isa => 'ArrayRef[Opoly::Board::Group]', is => 'ro', required => 1);
  has 'tiles' => (isa => 'ArrayRef', is => 'ro', required => 1);
  has 'start' => (isa => 'Opoly::Board::Tile', is => 'ro', required => 1);

  sub BUILD {
    # Test for a valid board

    my $self = shift;
    my $tiles = $self->tiles;

    my $i = 0; # expected address
    my $j = 0; # offset if tile is missing
    my @missing_tiles = 
      map {$_->[1] - 1} 
      grep { if ($_->[0] + $j == $_->[1]) { 0 } else {$j++; 1} } 
      map { [$i++, $_->address] } 
      @$tiles; 
    die "Board incomplete! Missing tiles " . join(', ', @missing_tiles) if @missing_tiles;

  }

}

