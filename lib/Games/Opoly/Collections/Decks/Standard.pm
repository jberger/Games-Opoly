use strict;
use warnings;

package Games::Opoly::Collections::Decks::Standard;

# Use Games::Opoly::Collections::Decks::Standard->deck to get a populated deck object

# definitions of decks and cards

use Games::Opoly::Deck;
use Games::Opoly::Deck::Card;
use Games::Opoly::Action;

my @cards = 
  map { Games::Opoly::Deck::Card->new($_) } 
  map { { 
   text => $_->[0], 
   others => $_->[1], 
   action => Games::Opoly::Action->new(description => $_->[0], code => $_->[2]) 
  } } (
    [ 'Pay $200', 'none', sub { $_[1]->must_pay(200) } ],
    [ 'Get out of Jail free', 'none', sub { $_[1]->get_out_of_jail_free($_[1]->get_out_of_jail_free() + 1) } ],
  );

my $deck = Games::Opoly::Deck->new( cards => \@cards );

sub deck {
  return $deck;
}
