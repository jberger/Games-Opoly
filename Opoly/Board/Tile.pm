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

      inner($player);

      #remove the buy action from the player's menu
      $player->remove_action("Buy");
    } 

  }

  method mortgage () {
    $self->mortgaged(1);

    my $collect = $self->price / 2;

    # sell all houses in group
    foreach my $tile ( @{ $self->group->tiles } ) {
      $self->owner->ui->add_message( "-- Selling houses in group\n" );
      $collect += $tile->houses * $tile->group->houses_cost() / 2;
      $tile->houses(0);
    }

    # remove group from $owner->monopolies
    $self->owner->monopolies( grep { $_ ne $self->group } @{ $self->owner->monopolies } );

    # collect benefits of sale
    $self->owner->collect( $collect );
  }

  method unmortgage () {  
    if ( $self->owner->pay( 1.1 * $self->price / 2 ) ) {
      $self->mortgaged(0);
    } 
  }

}

class Opoly::Board::Tile::Property 
  extends Opoly::Board::Tile::Ownable {

  has 'rent' => (isa => 'ArrayRef[Num]', is => 'ro', required => 1);

  has 'houses' => (isa => 'Num', is => 'rw', default => 0);

  has '+group' => (isa => 'Opoly::Board::Group::Property');

  augment arrive (Opoly::Player $player) {
    my $rent = $self->rent->[$self->houses];
    if ($self->houses == 0 and $self->group->monopoly) {
      $rent *= 2;
    }
    if ( $self->mortgaged ) {
      $rent = 0;
    }

    $player->pay($rent, $self->owner);

  }

  method _check_monopoly () {
    #check if this forms a monopoly
    if ( $self->group->monopoly) {
      #if so inform owner, to allow Houses action to appear
      $self->owner->monopolies( [ $self->group, @{ $self->owner->monopolies } ] );
    }
  }

  after unmortgage () {
    $self->_check_monopoly;
  }

  augment buy (Opoly::Player $player) {
    $self->_check_monopoly;
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
      $self->group->number_owned_by($self->owner) - 1
    ];
    $player->pay($rent, $self->owner);
  }

}

class Opoly::Board::Tile::Utility
  extends Opoly::Board::Tile::Ownable {

  has dice => (isa => 'Opoly::Dice', is => 'rw');

  augment arrive ( Opoly::Player $player ) {
    my @multipliers = (4, 10);
    my $multiplier = $multipliers[
      $self->group->number_owned_by($self->owner) - 1
    ];
    my $roll = $self->dice->roll_one();

    my $rent = $roll * $multiplier;
    $player->ui->add_message(
      "-- Rent: \$$rent = [$roll] x $multiplier\n" 
    );

    $player->pay($rent, $self->owner);
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

    $player->pay($amount);
  }

}
