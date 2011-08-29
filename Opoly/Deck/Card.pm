use MooseX::Declare;

class Opoly::Deck::Card {
  has 'used' => ( isa => 'Bool', is => 'rw', default => 0 );
}
