use MooseX::Declare;
use Method::Signatures::Modifiers;

class Opoly::UI::Test 
  extends Opoly::UI {

  has 'message' => (isa => 'Str', is => 'rw', default => '');
  has 'return'  => (isa => 'Str', is => 'rw', default => '');
  has 'user_input' => (isa => 'Str', is => 'rw', default => '');

  before log (Str $message) {
    $self->inform($message);
  }

  override inform (Str $message = '') {
    self->message( $message );
  }

  override choice ( ArrayRef[Str] $choices, Str $message? ) {
    $self->message( $message ) if $message;
    return $self->will_choose();
  }

  override input (Str $question) {
    $self->message( $question . " :> " );
    return $self->user_input();
  }

  override play_game () {
    until ($self->game->has_winner) {
      my $player = $self->game->current_player;

      my %actions = (
        "Status" => sub { $self->game->status },
        %{ $player->actions },
      );

      if ( @{ $player->monopolies } ) {
        $actions{"Houses"} = sub { $self->game->buy_houses };
      }

      if ( $player->num_roll ) {
        $actions{"Roll"} = sub { $self->game->roll };
      } else {
        $actions{"End Turn"} = sub { $self->game->end_turn };
      }

      my $choice = $self->choice([sort {$a cmp $b} keys %actions]);
      $actions{$choice}->();
    }
  }

}

