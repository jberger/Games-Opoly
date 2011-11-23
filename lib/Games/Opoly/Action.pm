use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::Action {

  use Carp;

  has 'description' => ( isa => 'Str', is => 'ro', predicate => 'has_description' );
  has 'code' => ( isa => 'CodeRef', is => 'ro', required => 1 );
  has 'args' => ( isa => 'ArrayRef', is => 'rw', default => sub { [] } );
  has 'available' => ( isa => 'Bool', is => 'rw', default => 1 );

  method action (Games::Opoly $game) {
    unless ($self->available) {
      carp "The specified action is marked as unavailable\n";
      return undef;
    }

    my @args = ($game);
    push @args, @{ $self->args } if @{ $self->args };
    return $self->code->(@args);
  }

}
