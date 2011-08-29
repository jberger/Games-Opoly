use MooseX::Declare;

class Opoly::Deck {
  use List::Util qw/shuffle/;

  has 'cards' => ( isa => 'ArrayRef[Opoly::Deck::Card]', is => 'rw', required => 1 );

  method _reuse () {
    foreach ( @{ $self->cards } ) {
      $_->seen(0);
    }
  }

  method _get_remaining ($deep = 0) {
    my $cards = $self->cards;
    my @remaining = grep { ! $_->seen } @$cards;
    if (! @remaining and @$cards and ! $deep) {
      $self->_reuse;
      @remaining = $self->_get_remaining(1);
    } else {
      return undef;
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

