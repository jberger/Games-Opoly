use MooseX::Declare;

class Opoly::UI {

  has 'message' => (isa => 'Str', is => 'rw', default => '');
  has 'game' => (isa => 'Opoly', is => 'rw', lazy => 1, default => '');

  method add_message (Str $message = '') {
    $self->message(
      $self->message() . $message
    );
  }

  method play_game () {

  }
}
