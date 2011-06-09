use MooseX::Declare;

class Opoly::Board::Tile {

  use Opoly::Board::Group;
  use Opoly::Player;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'group' => (isa => 'Opoly::Board::Group', is => 'ro', required => 1);
  has 'address' => (isa => 'Num', is => 'ro', required => 1);

  has 'occupants' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });

  
  method arrive (Opoly::Player $player) {
  # called on arrival ( usually after roll() )

    # remove player from old location
    $player->location->leave($player);

    # tell player and new location that the player has arrived
    $player->location($self);
    push @{ $self->occupants }, $player;
    $player->ui->add_message(
      "-- Arrived at: " . $self->name() . "\n"
    );

    # do class specific actions
    inner($player);

  }

  method leave (Opoly::Player $player) {
    $self->occupants([ 
      grep { !( $_ == $player ) } @{ $self->occupants }
    ]);

    #remove the buy action from the player's menu
    $player->remove_action("Buy");
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
  has 'mortgaged' => (isa => 'Bool', is => 'rw', default => 0);

  has '+group' => (isa => 'Opoly::Board::Group::Ownable');

  augment arrive (Opoly::Player $player) {
    
    if (! $self->has_owner) {
      #All ownable tiles behave the same if unowned, namely purchase if desired
      $player->add_action({ 'Buy ($' . $self->price . ") " => sub{ $self->buy($player) } });
    } else {
      #The tiles are different in their action if owned, therefore call class specific action here
      inner($player)
    }

  }

  method buy (Opoly::Player $player) {

    #if the player can pay
    if ( $player->pay( $self->price ) ) {
      #do the transaction
      $self->owner($player);
      push @{ $player->properties }, $self;

      #remove the buy action from the player's menu
      $player->remove_action("Buy");
    } else {
      #if the player doesn't have enough money
      $player->ui->add_message("---- You don't have enough money\n");
      return;
    }

  }

  method mortgage () {
    $self->mortgaged(1);
    $self->owner->collect( $self->price / 2 );
  }

  method unmortgage () {  
    if ( $self->owner->pay( 1.1 * $self->price / 2 ) ) {
      $self->mortgaged(0);
    } else {
      $self->owner->ui->add_message("---- You don't have enough money\n");
    }
  }

}

class Opoly::Board::Tile::Property 
  extends Opoly::Board::Tile::Ownable {

  has 'rent' => (isa => 'ArrayRef[Num]', is => 'ro', required => 1);

  has 'houses' => (isa => 'Num', is => 'rw', default => 0);
  has 'hotel' => (isa => 'Bool', is => 'rw', default => 0);

  augment arrive (Opoly::Player $player) {
    my $rent = $self->rent->[$self->houses];
    if ($self->houses == 0 and $self->group->monopoly) {
      $rent *= 2;
    }
    if ( $self->mortgaged ) {
      $rent = 0;
    }

    $player->pay($rent, $self->owner);
    $player->ui->add_message( '-- Paid: $' . $rent . " to " . $self->owner->name . "\n");
  }
  
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

  augment arrive (Opoly::Player $player) {
    my @rents = (25, 50, 100, 200);
    my $rent = $rents[
      1 + $self->group->number_owned_by($self->owner)
    ];
    if ($player->pay($rent, $self->owner) ) {
      $player->ui->add_message( '-- Paid: $' . $rent . " to " . $self->owner->name . "\n");
    } else {

    }
  }

}

class Opoly::Board::Tile::Utility
  extends Opoly::Board::Tile::Ownable {

  augment arrive ( Opoly::Player $player ) {
    
  }

}

class Opoly::Board::Tile::Arrest
  extends Opoly::Board::Tile {

  has 'jail' => (isa => 'Opoly::Board::Tile', is => 'rw');

  augment arrive ( Opoly::Player $player ) {
    $player->arrest($self->jail);
  }

}

class Opoly::Board::Tile::Tax 
  extends Opoly::Board::Tile {

  has 'amount' => (isa => 'Num', is => 'ro', required => 1);

  has 'percent' => (isa => 'Num', is => 'ro', default => 0);

  augment arrive (Opoly::Player $player) {

    my $amount = $self->amount;
    if ($self->percent) {
      my $percent_amount = $player->money * $self->percent / 100;
      $amount = 
        ($percent_amount < $amount)
        ? $percent_amount
        : $amount;
    }

    if ($player->pay($amount)) {
      $player->ui->add_message("-- Paid: \$$amount for " . $self->name . "\n");
    } else {
      $player->ui->add_message("-- Cannot afford " . $self->name . "\n");
    }
  }

}
