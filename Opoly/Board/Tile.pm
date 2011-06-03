use MooseX::Declare;

class Opoly::Board::Tile {

  use Opoly::Board::Group;
  use Opoly::Player;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'group' => (isa => 'Opoly::Board::Group', is => 'ro', required => 1);
  has 'address' => (isa => 'Num', is => 'ro', required => 1);

  has 'occupants' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });

  sub BUILD {
    my $self = shift;
    $self->group->add_tile($self);
  }

}

class Opoly::Board::Tile::Property 
  extends Opoly::Board::Tile
  with Opoly::Board::Role::Ownable {

  has 'rent' => (isa => 'ArrayRef[Num]', is => 'ro', required => 1);
  has 'houses' => (isa => 'Num', is => 'rw', default => 0);
  has 'hotel' => (isa => 'Bool', is => 'rw', default => 0);

  has '+group' => (isa => 'Opoly::Board::Group::Ownable');
  
}

role Opoly::Board::Role::Ownable {

  has 'price' => (isa => 'Num', is => 'ro', required => 1);
  has 'owner' => (isa => 'Opoly::Player', is => 'rw', default => undef);

}

role Opoly::Board::Role::Value {

  #has 'type' => ( isa => 'Str', is => 'ro', required => 1);
  has 'value' => ( isa => 'Num', is => 'ro', required => 1);

}
