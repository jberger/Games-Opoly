use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly {

  use Games::Opoly::Player;
  use Games::Opoly::Dice;
  #use Games::Opoly::Board;

  use List::Util qw/first sum/;
  use Scalar::Util qw/looks_like_number/;

  has 'board' => (isa => 'Games::Opoly::Board', is => 'ro', required => 1);
  has 'ui' => (isa => 'Games::Opoly::UI', is => 'ro', required => 1);

  has 'players' => (isa => 'ArrayRef[Games::Opoly::Player]', is => 'rw', default => sub{ [] });
  has 'current_player' => (isa => 'Games::Opoly::Player', is => 'rw', lazy => 1, builder => '_first_player');
  has 'winner' => (isa => 'Games::Opoly::Player', is => 'rw', predicate => 'has_winner');

  has 'dice' => (isa => 'Games::Opoly::Dice', is => 'ro', lazy => 1, builder => '_make_dice');
  has 'loaded_dice' => (isa => 'Bool', is => 'ro', default => 0);
  method _make_dice () {
    my $dice = $self->loaded_dice() ? Games::Opoly::Dice::Loaded->new( ui => $self->ui ) : Games::Opoly::Dice->new();

    # Populate Utility tiles with references to dice object
    map { $_->dice( $dice ) } 
      grep { $_->isa('Games::Opoly::Board::Tile::Utility') } 
      @{ $self->board->tiles };

    return $dice;
  }

  sub BUILD {
    my $self = shift;

    # pass game object to O::B::T::Card objects
    map { $_->game($self) }
      grep { $_->isa('Games::Opoly::Board::Tile::Card') }
      @{ $self->board->tiles };
  }

  method play_game () {
    $self->ui->game($self);
    $self->ui->play_game();
  }

  method add_player ( Games::Opoly::Player $player ) {
    $player->location($self->board->start);
    push @{ $self->players }, $player;
  }

  method _first_player () {
    my $first_player = $self->players->[0];
    $first_player->num_roll(1);
    $self->ui->log("First player: " . $first_player->name . "\n");
    return $first_player;
  }

  method roll () {
    my $player = $self->current_player;
    if ($player->in_jail) {
      $self->_roll_jail;
    } else {
      $self->_roll_normal;
    }
  }

  method _roll_jail () {
    my $player = $self->current_player;

    if ($player->get_out_of_jail_free) {
      my $choice = $player->ui->choice(
        [ qw/Yes No/ ],
        "-- Would you like to use your 'Get out of jail free' card?\n"
      );
      if ($choice eq 'Yes') {
        # turn in the card
        $player->get_out_of_jail_free( $player->get_out_of_jail_free() - 1 );
        $player->in_jail(0); # set free
        $self->_roll_normal;
        return;
      }
    }

    #player will not roll again for either outcome
    $player->num_roll(0); 

    my $dice = $self->dice;
    my $in_jail = $player->in_jail;

    # roll
    my @roll = $dice->roll_two;
    $player->ui->inform("-- Rolled: [$roll[0]][$roll[1]]\n");
    my $roll_total = sum @roll;
    my $is_doubles = ($roll[0] == $roll[1]);

    if ($is_doubles) {
      $self->ui->inform( "---- Doubles! You are set free!\n" );
      $player->in_jail(0); # set free
      $self->move($player, $roll_total);
      return;
    } 
    
    if ($in_jail < 3) {
      $player->ui->inform( "---- Not doubles. Better luck next time!\n" );
      $player->in_jail($in_jail + 1);
      return;
    }

    if ($player->must_pay(75)) {
      $player->ui->inform( "---- You paid to be released.\n" );
      $player->in_jail(0); # set free
      $self->move($player, $roll_total);
      return;
    } 
  }

  method _roll_normal () {

    my $player = $self->current_player;
    my $board = $self->board;
    my $dice = $self->dice;

    # roll
    my @roll = $dice->roll_two;
    $player->ui->log("-- Rolled: [$roll[0]][$roll[1]]\n");
    my $roll_total = sum @roll;
    my $is_doubles = ($roll[0] == $roll[1]);

    # doubles logic
    if ($is_doubles) {
      if ($player->num_roll < 3 ) {
        $player->num_roll( $player->num_roll() + 1 );
      } else {
        # Too many doubles: go to jail
        $player->ui->inform("-- 3 doubles in a row! Go to Jail!\n");
        $player->arrest($board->jail);
        return;
      }
    } else {
      $player->num_roll(0)
    }

    # move
    $self->move($player, $roll_total);
  }

  method move (Games::Opoly::Player $player, Num|Games::Opoly::Board::Tile $where) {
    ## Takes a player to move and either a tile object to move to
     # OR a number which represents the number of spaces to move
     # NOT the address to move to (think go 3 spaces not go to address 3) 

    my $board = $self->board;
    my $current_address = $player->location->address;

    my ($new_tile, $passed_go);
    if (blessed $where) {
      $new_tile = $where;
      $passed_go = ($where->address <= $current_address);
    } else {
      my $new_address = ($current_address + $where) % $board->num_tiles;
      $passed_go = int( ($current_address + $where) / $board->num_tiles);
      $new_tile = $board->get_tile($new_address);
    }

    # check for passing go and payout if so
    if ($passed_go) {
      $player->collect(200);
      $player->ui->log( "-- Go: Collect \$200\n" );
    }

    # call arrive method of new tile, get action (if returned)
    my $action = $new_tile->arrive($player);
    # if action is returned, call with self as option
    $action->action($self) if $action;

  }

  method buy_houses () {

    my $player = $self->current_player;
    my @groups = @{ $player->monopolies };

    my $group_name = $player->ui->choice(
      [ map {$_->name} @groups ],
      "-- Buy houses/hotels in which group?\n"
    );
    my ($group) = grep { $_->name eq $group_name } @groups;
    my @tiles = @{ $group->tiles };

    my $houses_cost = $group->houses_cost;

    my $houses_available = $group->houses_available;

    my $number;
    until (looks_like_number $number and $number <= $houses_available ) {
      $number = $self->ui->input( "-- How many houses ($houses_available at \$$houses_cost each)?" );
    }

    $group->buy_houses( $number );

  }

  method end_turn () {
    my $last_player = $self->current_player;
    $last_player->actions({});
    $last_player->num_roll(0);

    # if player reports that (s)he is no longer active (i.e. loses)
    unless ( $last_player->active ) {
      $last_player->ui->inform( "-- Sorry, you lose!\n" );

      $last_player->liquidate;

      # remove last_player from list of players
      $self->players([
        grep { $_ != $last_player } @{ $self->players }
      ]);
    }

    my $use_next = 0;
    my $next_player = first {
      if ($_ == $last_player) {
        $use_next = 1;
        return 0;
      }
      $use_next;
    } (@{ $self->players }, @{ $self->players });
    die "Panic! Could not determine next player" unless defined $next_player;

    $self->current_player( $next_player );
    $next_player->num_roll(1);

    $self->ui->inform("Next player: " . $self->current_player->name . "\n");
  }

  method status ( Games::Opoly::Player $input_player? ) {
    my @players = defined $input_player ? ($input_player) : @{ $self->players };
    $self->ui->inform( "------  Player Status  ------\n");

    foreach my $player (@players) {
      $self->ui->inform( $player->status );
    }

  }

}

