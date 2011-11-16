use MooseX::Declare;
use Method::Signatures::Modifiers;

class Opoly::Deck::Card {

  has 'text' => ( isa => 'Str', is => 'ro', required => 1 );

  # coderef which is passed to grep as `@others = grep {$code->($_)} @all_player_objects`
  # otherwise "all" or "none" (perhaps "rand")
  has 'others' => ( isa => 'CodeRef|Str', is => 'ro', required => 1 );

  # coderef which is called as $code->($player, @others) from above
  has 'action' => ( isa => 'Opoly::Action', is => 'ro', required => 1 );

  has 'seen' => ( isa => 'Bool', is => 'rw', default => 0 );
}
