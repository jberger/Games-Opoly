use MooseX::Declare;

class Opoly::Player {

  use Opoly::Dice;
  use Opoly::Board;
  use Opoly::Board::Tile;

  use List::Util qw/sum/;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'ui' => (isa => 'Opoly::UI', is => 'ro', required => 1);

  has 'location' => (isa => 'Opoly::Board::Tile', is => 'rw');
  has 'money' => (isa => 'Num', is => 'rw', default => 1500);
  has 'properties' => (isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub { [] } );
  has 'num_roll' => (isa => 'Num', is => 'rw', default => 0);
  has 'actions' => (isa => 'HashRef', is => 'rw', default => sub{ {} });
  has 'in_jail' => (isa => 'Num', is => 'rw', default => 0);

  method status () {
    my $message = "Name: " . $self->name . "\n";
    $message .= '-- Location: ' . $self->location->name . "\n";
    $message .= '-- Money: $' . $self->money . "\n";
    $message .= "-- Properties: \t" . join( "\n\t\t",
      map { $_->name . " [" . $_->group->name . "]" } 
      sort { $a->address <=> $b->address } 
      @{$self->properties}
    ) . "\n";
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

  method pay (Num $amount, Opoly::Player $payee?) {

    if ($self->money > $amount) {
      $self->money($self->money() - $amount);
    } else {
      return 0;
    }

    if (defined $payee) {
      $payee->collect($amount);
    }

    return 1;
  }

  method roll (Opoly::Board $board, Opoly::Dice $dice) {

    # roll
    my @roll = $dice->roll_two;
    $self->ui->message("-- Rolled: [$roll[0]][$roll[1]]\n");
    my $roll_total = sum @roll;
    my $is_doubles = ($roll[0] == $roll[1]);

    # doubles logic
    if ($is_doubles) {
      if ($self->num_roll < 3 ) {
        $self->num_roll( $self->num_roll() + 1 );
      } else {
        # Too many doubles: go to jail
        $self->ui->add_message("-- 3 doubles in a row! Go to Jail!\n");
        $self->arrest($board->jail);
        return;
      }
    } else {
      $self->num_roll(0)
    }

    # move
    my $current_address = $self->location->address;
    my $new_address = ($current_address + $roll_total) % $board->num_tiles;

    # check for passing go and payout if so
    my $passed_go = int( ($current_address + $roll_total) / $board->num_tiles);
    if ($passed_go) {
      $self->collect(200);
      $self->ui->add_message( "-- Go: Collect \$200\n" );
    }

    my $new_tile = $board->get_tile($new_address);
    $new_tile->arrive($self);

  }

  method arrest ( Opoly::Board::Tile $jail ) {
    $jail->arrive($self);
    $self->in_jail(1);
    $self->num_roll(0);
  } 

}


