use MooseX::Declare;

class Opoly::Board::Group {

  use Opoly::Board::Tile;

  has 'name' => ( isa => 'Str', is => 'ro', required => 1 );
  has 'tiles' => ( isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub{ [] });

  method add_tile (Opoly::Board::Tile $tile) {
    push @{ $self->tiles }, $tile;
  }

}

#class Opoly::Board::Group::Property
#extends Opoly::Board::Group {
#
#  has 'monopoly' => (isa => 'Bool', is => 'rw', default => 0);
#
#}

