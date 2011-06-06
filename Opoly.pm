use MooseX::Declare;

class Opoly {

  use Opoly::Player;
  #use Opoly::Board;

  use List::Util qw/first sum/;

  has 'players' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });
  has 'current_player' => (isa => 'Opoly::Player', is => 'rw', lazy => 1, builder => '_first_player');
  has 'board' => (isa => 'Opoly::Board', is => 'ro', required => 1);
  has 'ui' => (isa => 'Opoly::UI', is => 'ro', required => 1);
  has 'winner' => (isa => 'Bool', is => 'rw', default => 0);

  method play_game () {
    $self->ui->game($self);
    $self->ui->play_game();
  }

  method add_player ( Opoly::Player $player ) {
    $player->location($self->board->start);
    push @{ $self->players }, $player;
  }

  method _first_player () {
    my $first_player = $self->players->[0];
    $first_player->num_roll(1);
    $self->ui->message("First player: " . $first_player->name . "\n");
    $self->ui->flush_message;
    return $first_player;
  }

  method roll () {
    # get player and dice
    my $player = $self->current_player;
    my $dice = $self->board->dice;

    # roll
    my @roll = $dice->roll_two;
    $self->ui->message("-- Rolled: [$roll[0]][$roll[1]]\n");
    my $roll_total = sum @roll;
    my $is_doubles = ($roll[0] == $roll[1]);

    # doubles logic
    if ($is_doubles) {
      if ($player->num_roll < 3 ) {
        $player->num_roll( $player->num_roll() + 1 );
      } else {
        #TODO handle 3 doubles
        $player->num_roll(0);
        $roll_total = 0;
        $player->remove_choice("Roll");
      }
    } else {
      $player->num_roll(0)
    }

    # move
    my $current_address = $player->location->address;
    my $new_address = 
      $roll_total ? 
      ($current_address + $roll_total) % $self->board->num_tiles : 
      $self->board->jail->address; # doubles logic sets $roll_total to zero to indicate "go to jail"
    my $new_tile = $self->board->get_tile($new_address);
    $self->ui->add_message(
      "-- Arrived at: " . $new_tile->name() . "\n"
    );
    $new_tile->arrive($player);

  }

  method end_turn () {
    $self->ui->flush_message();

    my $last_player = $self->current_player;
    $last_player->choices({});

    my $use_next = 0;
    my $next_player = first {
      if ($_ == $last_player) {
        $use_next = 1;
        return 0;
      }
      $use_next;
    } (@{ $self->players }, @{ $self->players });
    die "Panic! Could not determine next player" unless defined $next_player;
    $self->current_player( $next_player );
    $next_player->num_roll(1);

    $self->ui->flush_message("Next player: " . $self->current_player->name . "\n");
    #$self->ui->flush_message;
  }

  method status ( Opoly::Player $player? ) {
    my @players = defined $player ? ($player) : @{ $self->players };
    $self->ui->add_message( "------  Player Status  ------\n");

    foreach my $p (@players) {
      $self->ui->add_message( $p->status );
    }

    $self->ui->flush_message;
  }

}

