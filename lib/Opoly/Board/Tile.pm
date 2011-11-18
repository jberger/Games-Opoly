use MooseX::Declare;
use Method::Signatures::Modifiers;

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
    my $old_location = $player->location;
    $old_location->leave($player) if $old_location;

    # tell player and new location that the player has arrived
    $player->location($self);
    push @{ $self->occupants }, $player;
    $player->ui->log(
      "-- Arrived at: " . $self->name() . "\n"
    );

    # do class specific actions
    my $action = inner($player);

    return $action if $action;
  }

  method leave (Opoly::Player $player) {
    $player->leave;
    $self->occupants([ 
      grep { !( $_ == $player ) } @{ $self->occupants }
    ]);
  }

  sub BUILD {
    my $self = shift;
    $self->group->add_tile($self);
  }

}

class Opoly::Board::Tile::Ownable 
  extends Opoly::Board::Tile {

  has 'price' => (isa => 'Num', is => 'ro', required => 1);
  has 'owner' => (isa => 'Opoly::Player', is => 'rw', predicate => 'has_owner', clearer => 'remove_owner');
  has 'mortgaged' => (isa => 'Bool', is => 'rw', default => 0);

  has '+group' => (isa => 'Opoly::Board::Group::Ownable');

  augment arrive (Opoly::Player $player) {
    my $action;
    
    if (! $self->has_owner) {
      #All ownable tiles behave the same if unowned, namely purchase if desired
      $player->add_action({ 'Buy ($' . $self->price . ")" => sub{ $self->buy($player) } });
    } else {
      #The tiles are different in their action if owned, therefore call class specific action here
      $action = inner($player);
    }

    return $action if $action;
  }

  after leave (Opoly::Player $player) {
    #remove the buy action from the player's menu
    $player->remove_action("Buy");
  }

  method buy (Opoly::Player $player) {

    #if the player can pay
    if ( $player->pay( $self->price ) ) {
      #do the transaction
      $self->take_possession($player);

      #remove the buy action from the player's menu
      $player->remove_action("Buy");
    } 

  }

  method take_possession (Opoly::Player $player) {
    $self->owner($player);
    push @{ $player->properties }, $self;
  }

  method mortgage () {
    $self->mortgaged(1);

    my $collect = $self->price / 2;

    # sell all houses in group
    $collect += inner();

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

    $player->must_pay($rent, $self->owner);

  }

  augment mortgage () {
    my $collect = 0;
    foreach my $tile ( @{ $self->group->tiles } ) {
      $self->owner->ui->inform( "-- Selling houses in group\n" );
      $collect += $tile->houses * $tile->group->houses_cost() / 2;
      $tile->houses(0);
    }
    return $collect;
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

  after take_possession (Opoly::Player $player) {
    $self->_check_monopoly;
  }
  
}

class Opoly::Board::Tile::Card
  extends Opoly::Board::Tile {
  
  has 'deck' => ( isa => 'Opoly::Deck', is => 'ro', required => 1);
  has 'game' => ( isa => 'Opoly', is => 'rw' ); #TODO make required once

  augment arrive (Opoly::Player $player) {
    my $card = $self->deck->draw;
    my @args = $player;
    my $others = $card->others;

    $self->game->ui->inform( '---- ' . $card->text . "\n" );
    my $action = $card->action;

    if ($others eq 'all') {
      push @args, @{ $self->game->players };
    } elsif (ref $others eq 'CODE') {
      push @args, grep { $others->($_) } @{ $self->game->players };
    }

    $action->args( \@args );

    return $action;
  }

}

class Opoly::Board::Tile::Railroad
  extends Opoly::Board::Tile::Ownable {

  augment arrive (Opoly::Player $player) {
    my @rents = (25, 50, 100, 200);
    my $rent = $rents[
      $self->group->number_owned_by($self->owner) - 1
    ];
    $player->must_pay($rent, $self->owner);
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
    $player->ui->log(
      "-- Rent: \$$rent = [$roll] x $multiplier\n" 
    );

    $player->must_pay($rent, $self->owner);
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

    $player->must_pay($amount);
  }

}
