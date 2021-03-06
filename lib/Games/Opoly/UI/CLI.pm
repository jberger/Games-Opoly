use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::UI::CLI 
  extends Games::Opoly::UI {

  before log (Str $message) {
    $self->inform($message);
  }

  override inform (Str $message = '') {
    print $message;
  }

  method turn_menu () {
    
  }

  override choice ( ArrayRef[Str] $choices, Str $message? ) {
    print $message if $message;

    my @possible_responses;
    while (1) {
      print "-- Select: " . join(', ', @$choices) . " :> ";

      my $user_response = <>;
      ## prevent rare use of undef warnings
      $user_response //= ''; 		#/# fix highlighter

      chomp $user_response;
      @possible_responses = grep { /^$user_response/i } @$choices;
      last if @possible_responses == 1;
      print "---- Could not understand response!\n";
    }

    return $possible_responses[0];
  }

  override input (Str $question) {
    print $question . " :> ";
    chomp( my $response = <> );
    return $response;
  }

  override play_game () {
    until ($self->game->has_winner) {
      my $player = $self->game->current_player;

      my %actions = (
        "Status" => sub { $self->game->status },
        %{ $player->actions },
      );

      if ( @{ $player->monopolies } ) {
        $actions{"Houses"} = sub { $self->game->buy_houses };
      }

      if ( $player->num_roll ) {
        $actions{"Roll"} = sub { $self->game->roll };
      } else {
        $actions{"End Turn"} = sub { $self->game->end_turn };
      }

      my $choice = $self->choice([sort {$a cmp $b} keys %actions]);
      $actions{$choice}->();
    }
  }

}

