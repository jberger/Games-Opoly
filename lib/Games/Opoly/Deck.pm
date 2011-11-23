use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::Deck {
  use List::Util qw/shuffle/;
  use Carp;

  has 'cards' => ( isa => 'ArrayRef[Games::Opoly::Deck::Card]', is => 'rw', required => 1 );

  method _reuse () {
    foreach ( @{ $self->cards } ) {
      $_->seen(0);
    }
  }

  method _get_remaining ($deep = 0) {
    my $cards = $self->cards;
    my @remaining = grep { ! $_->seen } @$cards;
    if (! @remaining and @$cards) {
      croak "Could not find a usable card" if $deep;
      $self->_reuse;
      @remaining = $self->_get_remaining(1);
    }
    return @remaining;
  }

  method draw () {
    my @cards = shuffle $self->_get_remaining;
    my $card = $cards[0];

    $card->seen(1);

    return $card;
  }
}

