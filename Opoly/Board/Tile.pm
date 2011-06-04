use MooseX::Declare;

class Opoly::Board::Tile {

  use Opoly::Board::Group;
  use Opoly::Player;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'group' => (isa => 'Opoly::Board::Group', is => 'ro', required => 1);
  has 'address' => (isa => 'Num', is => 'ro', required => 1);

  has 'occupants' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });

  method arrive (Opoly::Player $player) {

    # remove player from old location
    $player->location->leave($player);

    # tell player and new location that the player has arrived
    $player->location($self);
    push @{ $self->occupants }, $player;

    # specific tile types should override this method BUT be sure to call it!
  }

  method leave (Opoly::Player $player) {
    $self->occupants(
      grep { !( $_ == $player ) } @{ $self->occupants }
    );
  }

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

  #has '+group' => (isa => 'Opoly::Board::Group::Ownable');
  
}

class Opoly::Board::Tile::Card
  extends Opoly::Board::Tile {
  
  has 'deck' => (isa => 'Str', is => 'ro', builder => '_set_deck', lazy => 1);

  method _set_deck {
    return $self->name;
  }

}

class Opoly::Board::Tile::Railroad
  with Opoly::Board::Role::Ownable
  extends Opoly::Board::Tile {

}

class Opoly::Board::Tile::Utility
  with Opoly::Board::Role::Ownable
  extends Opoly::Board::Tile {

}

class Opoly::Board::Tile::Tax 
  extends Opoly::Board::Tile {



}

role Opoly::Board::Role::Ownable {

  has 'price' => (isa => 'Num', is => 'ro', required => 1);
  has 'owner' => (isa => 'Opoly::Player', is => 'rw', default => undef);

}

role Opoly::Board::Role::Value {

  #has 'type' => ( isa => 'Str', is => 'ro', required => 1);
  has 'value' => ( isa => 'Num', is => 'ro', required => 1);

}
