use MooseX::Declare;

class Opoly::UI::CLI 
  extends Opoly::UI {

  method flush_message (Str $message = '') {
    $self->add_message($message);
    print $self->message;
    $self->message('');
  }

  method turn_menu () {
    
  }

  method choice (ArrayRef[Str] $choices) {
    $self->flush_message;

    my @possible_responses;
    while (1) {
      print "-- Select: " . join(', ', @$choices) . " :> ";
      chomp(my $user_response = <>);
      @possible_responses = grep { /^$user_response/i } @$choices;
      last if @possible_responses == 1;
      print "---- Could not understand response!\n";
    }

    return $possible_responses[0];
  }

  override play_game () {
    until ($self->game->has_winner) {
      my %choices = (
        "Status" => sub { $self->game->status },
        "End Turn" => sub { $self->game->end_turn },
        %{ $self->game->current_player->choices },
      );

      if ( $self->game->current_player->num_roll ) {
        %choices = (%choices, "Roll" => sub{ $self->game->roll });
      }

      my $choice = $self->choice([sort {$a cmp $b} keys %choices]);
      $choices{$choice}->();
    }
  }

}

