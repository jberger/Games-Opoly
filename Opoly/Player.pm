use MooseX::Declare;

class Opoly::Player {

  use Opoly::Board::Tile;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'location' => (isa => 'Opoly::Board::Tile', is => 'rw');
  has 'money' => (isa => 'Num', is => 'rw', default => 1500);
  has 'properties' => (isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub { [] } );
  has 'num_roll' => (isa => 'Num', is => 'rw', default => 0);
  has 'choices' => (isa => 'HashRef', is => 'rw', default => sub{ {} });

}


