use MooseX::Declare;

class Opoly::UI::CLI {

  has 'message' => (isa => 'Str', is => 'rw', default => '');

  method add_message (Str $message = '') {
    $self->message(
      $self->message() . $message
    );
  }

  method flush_message (Str $message = '') {
    $self->add_message($message);
    print $self->message;
    $self->message('');
  }

}
