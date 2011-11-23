use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::UI::Test 
  extends Games::Opoly::UI {

  has 'message' => (isa => 'Str', is => 'rw', default => '');
  has 'return'  => (isa => 'Str', is => 'rw', default => '');
  has 'user_input' => (isa => 'Str', is => 'rw', default => '');

  method clear () {
    $self->message('');
    $self->return('');
    $self->user_input('');
    return 1;
  }

  before log (Str $message) {
    $self->inform($message);
  }

  override inform (Str $message = '') {
    $self->message( $message );
  }

  override choice ( ArrayRef[Str] $choices, Str $message? ) {
    $self->message( $message ) if $message;
    my $user_input = $self->user_input;
    if ( 1 == grep { $_ eq $user_input } @$choices ) {
      return $user_input;
    } else {
      die "$user_input is not a valid choice";
    }
  }

  override input (Str $question) {
    $self->message( $question );
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

