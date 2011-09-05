use MooseX::Declare;

class Opoly::UI {

  has 'message' => (isa => 'Str', is => 'rw', default => '');
  has 'game_log' => (isa => 'ArrayRef[Str]', is => 'rw', default => sub{ [] });
  has 'game' => (isa => 'Opoly', is => 'rw', lazy => 1, default => '');

  method log (Str $message) {
    push @{ $self->game_log }, $message;
  }

  method inform (Str $message = '') {
    #override per UI implementation
  }

  #deprecated use inform or log
  method add_message (Str $message = '') {
    $self->message(
      $self->message() . $message
    );
  }

  method play_game () {

  }
}
