use MooseX::Declare;

class Opoly::Board::Tile {

  use Opoly::Board::Group;
  use Opoly::Player;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'group' => (isa => 'Opoly::Board::Group', is => 'ro', required => 1);
  has 'address' => (isa => 'Num', is => 'ro', required => 1);

  has 'occupants' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });

  
  method arrive (Opoly::Player $player) {
  # specific tile types should after or override (BUT be sure to call) this method

    # remove player from old location
    $player->location->leave($player);

    # tell player and new location that the player has arrived
    $player->location($self);
    push @{ $self->occupants }, $player;

    # do class specific actions
    inner($player);

  }

  method leave (Opoly::Player $player) {
    $self->occupants(
      grep { !( $_ == $player ) } @{ $self->occupants }
    );

    #remove the buy choice from the player's menu
    $player->remove_choice("Buy");
  }

  sub BUILD {
    my $self = shift;
    $self->group->add_tile($self);
  }

}

class Opoly::Board::Tile::Ownable 
  extends Opoly::Board::Tile {

  has 'price' => (isa => 'Num', is => 'ro', required => 1);
  has 'owner' => (isa => 'Opoly::Player', is => 'rw', predicate => 'has_owner');

  augment arrive (Opoly::Player $player) {
    unless ($self->has_owner) {
      $player->add_choice({ 'Buy ($' . $self->price . ") " => sub{ $self->buy($player) } });
    }
    inner($player);
  }

  method buy (Opoly::Player $player) {
    #check that the player has enough money
    if ($player->money < $self->price) {
      return "---- You don't have enough money\n";
    }

    #do the transaction
    $player->money( $player->money - $self->price );
    $self->owner($player);
    push @{ $player->properties }, $self;

    #remove the buy choice from the player's menu
    $player->remove_choice("Buy");
  }

}

class Opoly::Board::Tile::Property 
  extends Opoly::Board::Tile::Ownable {

  has 'rent' => (isa => 'ArrayRef[Num]', is => 'ro', required => 1);
  has 'houses' => (isa => 'Num', is => 'rw', default => 0);
  has 'hotel' => (isa => 'Bool', is => 'rw', default => 0);

  #has '+group' => (isa => 'Opoly::Board::Group::Ownable');
  
}

class Opoly::Board::Tile::Card
  extends Opoly::Board::Tile {
  
  has 'deck' => (isa => 'Str', is => 'ro', builder => '_set_deck', lazy => 1);

  method _set_deck () {
    return $self->name;
  }

}

class Opoly::Board::Tile::Railroad
  extends Opoly::Board::Tile::Ownable {

}

class Opoly::Board::Tile::Utility
  extends Opoly::Board::Tile::Ownable {

}

class Opoly::Board::Tile::Tax 
  extends Opoly::Board::Tile {



}

role Opoly::Board::Role::Value {

  #has 'type' => ( isa => 'Str', is => 'ro', required => 1);
  has 'value' => ( isa => 'Num', is => 'ro', required => 1);

}
