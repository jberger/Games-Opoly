use MooseX::Declare;

class 'Opoly::Board' {

  use Opoly::Board::Group;
  use Opoly::Board::Tile;

  has Groups => (isa => 'ArrayRef[Opoly::Board::Group]', is => 'ro', builder => '_build_board');
  has Start => (isa => 'Opoly::Board::Tile', is => 'ro', writer => '_set_start');

  method _build_board () {


  }
  
  method _set_start ('Opoly::Board::Tile' $tile) {
    return $tile;
  }

}
