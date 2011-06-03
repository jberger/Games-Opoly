use MooseX::Declare;

class Opoly {

  use Opoly::Player;
  use Opoly::Board;

  has 'players' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });

}
