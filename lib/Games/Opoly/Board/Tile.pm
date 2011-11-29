use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::Board::Tile {

  use Games::Opoly::Board::Group;
  use Games::Opoly::Player;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'group' => (isa => 'Games::Opoly::Board::Group', is => 'ro', required => 1);
  has 'address' => (isa => 'Num', is => 'ro', required => 1);

  has 'occupants' => (isa => 'ArrayRef[Games::Opoly::Player]', is => 'rw', default => sub{ [] });

  
  method arrive (Games::Opoly::Player $player) {
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

    if ($action) {
      return $action;
    } else {
      return 0;
    }
  }

  method leave (Games::Opoly::Player $player) {
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

class Games::Opoly::Board::Tile::Ownable 
  extends Games::Opoly::Board::Tile {

  has 'price' => (isa => 'Num', is => 'ro', required => 1);
  has 'owner' => (isa => 'Games::Opoly::Player', is => 'rw', predicate => 'has_owner', clearer => 'remove_owner');
  has 'mortgaged' => (isa => 'Bool', is => 'rw', default => 0);

  has '+group' => (isa => 'Games::Opoly::Board::Group::Ownable');

  method get_rent () {
    return 0; #override per subclass
  }

  augment arrive (Games::Opoly::Player $player) {
    my $action;
    
    if (! $self->has_owner) {
      #All ownable tiles behave the same if unowned, namely purchase if desired
      $player->add_action({ 'Buy ($' . $self->price . ")" => sub{ $self->buy($player) } });
    } else {
      #The tiles are different in their action if owned, therefore call class specific action here
      unless ($self->mortgaged) {
        $self->pay_rent($player);
        $action = inner($player);
      }
    }

    return $action if $action;
  }

  method pay_rent (Games::Opoly::Player $player) {
    my $rent = $self->get_rent;
    $player->must_pay($rent, $self->owner);
  }

  after leave (Games::Opoly::Player $player) {
    #remove the buy action from the player's menu
    $player->remove_action("Buy");
  }

  method buy (Games::Opoly::Player $player) {

    #if the player can pay
    if ( $player->pay( $self->price ) ) {
      #do the transaction
      $self->take_possession($player);

      #remove the buy action from the player's menu
      $player->remove_action("Buy");
    } 

  }

  method take_possession (Games::Opoly::Player $player) {
    $self->owner($player);
    push @{ $player->properties }, $self;
  }

  method mortgage () {
    $self->mortgaged(1);

    my $collect = $self->price / 2;

    # sell all houses in group
    $collect += inner() || 0;

    # remove group from $owner->monopolies
    # (although this seems asymmetric, since monopoly isn't done here, this seems safest)
    $self->owner->monopolies( grep { $_ != $self->group } @{ $self->owner->monopolies } );

    # collect benefits of sale
    $self->owner->collect( $collect );
  }

  method unmortgage () {  
    if ( $self->owner->pay( 1.1 * $self->price / 2 ) ) {
      $self->mortgaged(0);
    } 
  }

}

class Games::Opoly::Board::Tile::Property 
  extends Games::Opoly::Board::Tile::Ownable {

  has 'rent' => (isa => 'ArrayRef[Num]', is => 'ro', required => 1);

  has 'houses' => (isa => 'Num', is => 'rw', default => 0);

  has '+group' => (isa => 'Games::Opoly::Board::Group::Property');

  override get_rent () {
    my $rent = $self->rent->[$self->houses];
    if ($self->houses == 0 and $self->group->monopoly) {
      $rent *= 2;
    }
    return $rent;
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

  after take_possession (Games::Opoly::Player $player) {
    $self->_check_monopoly;
  }
  
}

class Games::Opoly::Board::Tile::Railroad
  extends Games::Opoly::Board::Tile::Ownable {

  has 'rent'       => ( isa => 'Num', is => 'ro', default => 25 );
  has 'multiplier' => ( isa => 'Int', is => 'ro', default => 2  );

  override get_rent () {
    my $rent = $self->rent;
    $rent *= $self->multiplier ** ( $self->group->number_owned_by($self->owner) - 1 );
    return $rent;
  }

}

class Games::Opoly::Board::Tile::Utility
  extends Games::Opoly::Board::Tile::Ownable {

  has dice => (isa => 'Games::Opoly::Dice', is => 'rw');

  override get_rent () {
    my @multipliers = (4, 10);
    my $multiplier = $multipliers[
      $self->group->number_owned_by($self->owner) - 1
    ];
    my $roll = $self->dice->roll_one();

    my $rent = $roll * $multiplier;

    if (wantarray) {
      return ($rent, $roll, $multiplier);
    } else {
      return $rent;
    }
  }

  override pay_rent ( Games::Opoly::Player $player ) {
    my ($rent, $roll, $multiplier) = $self->get_rent;

    $player->ui->log(
      "-- Rent: \$$rent = [$roll] x $multiplier\n" 
    );

    $player->must_pay($rent, $self->owner);
  }

}

class Games::Opoly::Board::Tile::Card
  extends Games::Opoly::Board::Tile {
  
  has 'deck' => ( isa => 'Games::Opoly::Deck', is => 'ro', required => 1);
  has 'game' => ( isa => 'Games::Opoly', is => 'rw' ); #TODO make required once

  augment arrive (Games::Opoly::Player $player) {
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

class Games::Opoly::Board::Tile::Arrest
  extends Games::Opoly::Board::Tile {

  has 'jail' => (isa => 'Games::Opoly::Board::Tile', is => 'rw');

  augment arrive ( Games::Opoly::Player $player ) {
    $player->arrest($self->jail);
  }

}

class Games::Opoly::Board::Tile::Tax 
  extends Games::Opoly::Board::Tile {

  has 'amount' => (isa => 'Num', is => 'ro', required => 1);

  has 'percent' => (isa => 'Num', is => 'ro', default => 0);

  augment arrive (Games::Opoly::Player $player) {

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
