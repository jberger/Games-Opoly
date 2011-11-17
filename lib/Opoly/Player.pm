use MooseX::Declare;
use Method::Signatures::Modifiers;

class Opoly::Player {

  use Opoly::Dice;
  use Opoly::Board;
  use Opoly::Board::Tile;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'ui' => (isa => 'Opoly::UI', is => 'ro', required => 1);

  has 'location' => (isa => 'Opoly::Board::Tile', is => 'rw', clearer => 'leave');
  has 'money' => (isa => 'Num', is => 'rw', default => 1500);
  has 'properties' => (isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub { [] } );
  has 'monopolies' => (isa => 'ArrayRef[Opoly::Board::Group::Ownable]', is => 'rw', default => sub { [] } );
  has 'num_roll' => (isa => 'Num', is => 'rw', default => 0);
  has 'actions' => (isa => 'HashRef', is => 'rw', default => sub{ {} });
  has 'in_jail' => (isa => 'Num', is => 'rw', default => 0);
  has 'get_out_of_jail_free' => (isa => 'Num', is => 'rw', default => 0);
  has 'active' => (isa => 'Bool', is => 'rw', default => 1);

  method status () {
    my $message = "Name: " . $self->name . "\n";
    $message .= '-- Location: ' . $self->location->name . "\n";
    $message .= '-- Money: $' . $self->money . "\n";
    $message .= "-- Properties: \t" . join( "\n\t\t",
      map { 
        $_->name . 
        " [" . $_->group->name . "] [" . 
        (
          $_->houses==5 
            ? "hotel" 
            : $_->houses==1 
              ? "1 house" 
              : $_->houses . " houses"
        ) .
        "]" } 
      sort { $a->address <=> $b->address }
      grep { $_->isa('Opoly::Board::Tile::Property') }
      @{$self->properties}
    ) . "\n";
    $message .= "-- Other Properties: \t" . join( "\n\t\t\t",
      map { $_->name }
      sort { $a->address <=> $b->address }
      grep { ! $_->isa('Opoly::Board::Tile::Property') }
      @{$self->properties}
    ) . "\n";

    return $message;
  }

  method add_action (HashRef $action) {
    my %actions = (%{$self->actions}, %$action);
    $self->actions(\%actions);
  }

  method remove_action (Str $key_stem) {
    my @remove_keys = grep { /^$key_stem/i } keys %{ $self->actions };

    die "Key to remove not uniquely determined" if (@remove_keys > 1);
    return 0 if (@remove_keys == 0);

    my %actions = %{$self->actions};
    delete $actions{$remove_keys[0]};
    $self->actions(\%actions);
  }

  method collect (Num $amount) {
    $self->money($self->money() + $amount);
  }

  method must_pay (Num $amount, Opoly::Player $payee?) {
    my @args = ($amount);
    push @args, $payee if defined $payee;

    while (1) {

      return 1 if ( $self->pay(@args) );
      ## If player cannot pay:

      my $method = $self->ui->choice(
        [qw/ Mortgage Trade Status Resign /],
        "-- How are you going to pay?\n"
      );

      last if ($method eq 'Resign');

      if ($method eq 'Status') {
        $self->ui->inform( $self->status );

      } elsif ($method eq "Mortgage") {

      } elsif ($method eq 'Trade') {

      }

    }

    ## Player resigns:

    if (defined $payee) {
      $_->take_possession($payee) for @{ $self->property };
    }

    $self->active(0); # lose game
  }

  method pay (Num $amount, Opoly::Player $payee?) {

    if ($self->money > $amount) {
      $self->money($self->money() - $amount);
      my $message = '---- Paid: $' . $amount;

      if (defined $payee) {
        $payee->collect($amount);
        $message .= " to " . $payee->name;
      }

      $self->ui->inform( $message . "\n");

      return 1;
    } else {
      $self->ui->inform("---- You don't have enough money\n");

      return 0;
    }
  }

  method arrest ( Opoly::Board::Tile $jail ) {
    $jail->arrive($self);
    $self->in_jail(1);
    $self->num_roll(0);
  } 

  method liquidate () {
    # take player off the board 
    $self->location->leave($self);
    # return any remainging tiles (shouldn't be any after firesale)
    $_->remove_owner for @{ $self->properties };
  }

}


