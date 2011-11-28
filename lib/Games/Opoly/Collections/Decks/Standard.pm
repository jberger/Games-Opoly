use strict;
use warnings;

package Games::Opoly::Collections::Decks::Standard;

# Use Games::Opoly::Collections::Decks::Standard->deck to get a populated deck object

# definitions of decks and cards

use Games::Opoly::Deck;
use Games::Opoly::Deck::Card;
use Games::Opoly::Action;

my $deck = Games::Opoly::Deck->new();

map { $deck->add_card(@$_) } 
  (
    [ 'Pay $200', sub { $_[1]->must_pay(200) } ],
    [ 'Get out of Jail free', sub { $_[1]->get_out_of_jail_free($_[1]->get_out_of_jail_free() + 1) } ],
  );

sub deck {
  return $deck;
}
