use MooseX::Declare;

class Opoly {

  use Opoly::Player;
  #use Opoly::Board;

  use List::Util qw/first/;

  has 'players' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });
  has 'current_player' => (isa => 'Opoly::Player', is => 'rw', lazy => 1, builder => '_first_player');
  has 'board' => (isa => 'Opoly::Board', is => 'ro', required => 1);
  has 'ui' => (isa => 'Opoly::UI::CLI', is => 'ro', required => 1);

  method add_player ( Opoly::Player $player ) {
    $player->location($self->board->start);
    push @{ $self->players }, $player;
  }

  method _first_player () {
    my $first_player = $self->players->[0];
    $self->ui->message("First player: " . $first_player->name . "\n");
    $self->ui->flush_message;
    return $first_player;
  }

  method roll () {
    my $player = $self->current_player;
    my $dice = $self->board->dice;

    my @roll = $dice->roll_two;
    $self->ui->message("-- Rolled: [$roll[0],$roll[1]]\n")
    
  }

  method end_turn () {
    $self->ui->flush_message();

    my $last_player = $self->current_player;
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

    $self->ui->flush_message("Next player: " . $self->current_player->name . "\n");
    #$self->ui->flush_message;
  }

}
