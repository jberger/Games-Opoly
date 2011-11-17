use strict;
use warnings;

package Opoly::Collections::Decks::Standard;

# Use Opoly::Collections::Decks::Standard->deck to get a populated deck object

# definitions of decks and cards

use Opoly::Deck;
use Opoly::Deck::Card;
use Opoly::Action;

my @cards = 
  map { Opoly::Deck::Card->new($_) } 
  map { { 
   text => $_->[0], 
   others => $_->[1], 
   action => Opoly::Action->new(description => $_->[0], code => $_->[2]) 
  } } (
    [ 'Pay $200', 'none', sub { $_[1]->must_pay(200) } ],
    [ 'Get out of Jail free', 'none', sub { $_[1]->get_out_of_jail_free($_[1]->get_out_of_jail_free() + 1) } ],
  );

my $deck = Opoly::Deck->new( cards => \@cards );

sub deck {
  return $deck;
}