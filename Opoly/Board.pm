use MooseX::Declare;

class Opoly::Board {

  use Opoly::Board::Group;
  use Opoly::Board::Tile;

  has 'groups' => (isa => 'ArrayRef[Opoly::Board::Group]', is => 'ro', required => 1);
  has 'start' => (isa => 'Opoly::Board::Tile', is => 'ro', required => 1);

}
