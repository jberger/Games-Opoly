use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::UI {

  #has 'message' => (isa => 'Str', is => 'rw', default => '');
  has 'game_log' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub{ [] });
  has 'game' => (isa => 'Games::Opoly', is => 'rw', lazy => 1, default => '');

  method log (Str $message) {
    push @{ $self->game_log }, $message;
  }

  method inform (Str $message) {
    #override/otherwise reimplement per UI implementation
    $self->log($message) if $message;
  }

  method input (Str $question) {

  }

  method choice (ArrayRef[Str] $choices, Str $message?) {
    #override per UI implementation
  }

  method play_game () {

  }
}
