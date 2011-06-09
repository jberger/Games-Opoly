use MooseX::Declare;

class Opoly {

  use Opoly::Player;
  use Opoly::Dice;
  #use Opoly::Board;

  use List::Util qw/first/;

  has 'board' => (isa => 'Opoly::Board', is => 'ro', required => 1);
  has 'ui' => (isa => 'Opoly::UI', is => 'ro', required => 1);

  has 'players' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });
  has 'current_player' => (isa => 'Opoly::Player', is => 'rw', lazy => 1, builder => '_first_player');
  has 'winner' => (isa => 'Opoly::Player', is => 'rw', predicate => 'has_winner');

  has 'dice' => (isa => 'Opoly::Dice', is => 'ro', lazy => 1, builder => '_make_dice');
  has 'loaded_dice' => (isa => 'Bool', is => 'ro', default => 0);
  method _make_dice () {
    $self->loaded_dice() ? Opoly::Dice::Loaded->new( ui => $self->ui ) : Opoly::Dice->new();
  }

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

  #N.B. roll method moved to Opoly::Player

  #Perhaps this method should be in Opoly::Player too.
  method end_turn () {
    $self->ui->flush_message();

    my $last_player = $self->current_player;
    $last_player->actions({});

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

