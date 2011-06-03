use MooseX::Declare;

class 'Opoly::Player' {

  use Opoly::Board::Tile;

  has 'Name' => (isa => 'Str', is => 'ro', required => 1);
  has 'Location' => (isa => 'Opoly::Tile', is => 'rw', required => 1);
  has 'Money' => (isa => 'Num', is => 'rw', required => 1);
  has 'Properties' => (isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub { [] } );

}
