use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::Deck {
  use List::Util qw/shuffle/;
  use Carp;

  use Games::Opoly::Deck::Card;
  use Games::Opoly::Action;

  has 'cards' => ( isa => 'ArrayRef[Games::Opoly::Deck::Card]', is => 'rw', default => sub{ [] } );

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

  method add_card (Str $text, CodeRef $code, CodeRef|Str $others = 'none') {
    my $card = Games::Opoly::Deck::Card->new(
      text => $text,
      others => $others,
      action => Games::Opoly::Action->new(
        description => $text, 
        code => $code
      ),
    );

    push @{ $self->cards }, $card;
  }
}

