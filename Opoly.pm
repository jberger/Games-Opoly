use MooseX::Declare;

class Opoly {

  use Opoly::Player;
  use Opoly::Dice;
  #use Opoly::Board;

  use List::Util qw/first sum/;
  use Scalar::Util qw/looks_like_number/;

  has 'board' => (isa => 'Opoly::Board', is => 'ro', required => 1);
  has 'ui' => (isa => 'Opoly::UI', is => 'ro', required => 1);

  has 'players' => (isa => 'ArrayRef[Opoly::Player]', is => 'rw', default => sub{ [] });
  has 'current_player' => (isa => 'Opoly::Player', is => 'rw', lazy => 1, builder => '_first_player');
  has 'winner' => (isa => 'Opoly::Player', is => 'rw', predicate => 'has_winner');

  has 'dice' => (isa => 'Opoly::Dice', is => 'ro', lazy => 1, builder => '_make_dice');
  has 'loaded_dice' => (isa => 'Bool', is => 'ro', default => 0);
  method _make_dice () {
    my $dice = $self->loaded_dice() ? Opoly::Dice::Loaded->new( ui => $self->ui ) : Opoly::Dice->new();

    # Populate Utility tiles with references to dice object
    map { $_->dice( $dice ) } 
      grep { $_->isa('Opoly::Board::Tile::Utility') } 
      @{ $self->board->tiles };

    return $dice;
  }

  method play_game () {
    $self->ui->game($self);
    $self->ui->play_game();
  }

  method add_player ( Opoly::Player $player ) {
    $player->location($self->board->start);
    push @{ $self->players }, $player;
  }

  method _first_player () {
    my $first_player = $self->players->[0];
    $first_player->num_roll(1);
    $self->ui->message("First player: " . $first_player->name . "\n");
    $self->ui->flush_message;
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
      $player->ui->add_message( 
        "-- Would you like to use your 'Get out of jail free' card?\n"
      );
      my $choice = $player->ui->choice( [ qw/Yes No/ ] );
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
    $player->ui->message("-- Rolled: [$roll[0]][$roll[1]]\n");
    my $roll_total = sum @roll;
    my $is_doubles = ($roll[0] == $roll[1]);

    if ($is_doubles) {
      $self->ui->add_message( "---- Doubles! You are set free!\n" );
      $player->in_jail(0); # set free
      $self->move($player, $roll_total);
      return;
    } 
    
    if ($in_jail < 3) {
      $player->ui->add_message( "---- Not doubles. Better luck next time!\n" );
      $player->in_jail($in_jail + 1);
      return;
    }

    if ($player->pay(75)) {
      $player->ui->add_message( "---- You paid to be released.\n" );
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
    $player->ui->message("-- Rolled: [$roll[0]][$roll[1]]\n");
    my $roll_total = sum @roll;
    my $is_doubles = ($roll[0] == $roll[1]);

    # doubles logic
    if ($is_doubles) {
      if ($player->num_roll < 3 ) {
        $player->num_roll( $player->num_roll() + 1 );
      } else {
        # Too many doubles: go to jail
        $player->ui->add_message("-- 3 doubles in a row! Go to Jail!\n");
        $player->arrest($board->jail);
        return;
      }
    } else {
      $player->num_roll(0)
    }

    # move
    $self->move($player, $roll_total);
  }

  method move (Opoly::Player $player, Num|Opoly::Board::Tile $where) {
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
      $player->ui->add_message( "-- Go: Collect \$200\n" );
    }

    $new_tile->arrive($player);
  }

  method buy_houses () {

    my $player = $self->current_player;
    my @groups = @{ $player->monopolies };

    $player->ui->add_message( "-- Buy houses/hotels in which group?\n" );
    my $group_name = $player->ui->choice( [ map {$_->name} @groups ] );
    my ($group) = grep { $_->name eq $group_name } @groups;
    my @tiles = @{ $group->tiles };

    my $houses_cost = $group->houses_cost;

    my $houses_available = sum map { 5 - $_->houses } @tiles;
    $self->ui->add_message( "-- There are $houses_available houses available\n" );

    my $number;
    until (looks_like_number $number and $number <= $houses_available ) {
      $number = $self->ui->input( "-- How many houses (\$$houses_cost each)?" );
    }

    my $num_each = int( $number / ( scalar @tiles ) );
    my $remaining = $number % scalar @tiles;

    my @tiles_houses = 
      map  { [$_, $num_each + ($remaining-- > 0)] } 
      sort {
        $a->houses	<=> $b->houses		||
        $b->rent->[0]	<=> $a->rent->[0]	||
        $b->address	<=> $a->address 
      } 
      @tiles;

    my $cost = sum map { $_->[1] * $houses_cost } @tiles_houses;

    if ( $player->pay($cost) ) {
      map { 
        my ($tile, $num) = @$_;
        $tile->houses( $num + $tile->houses );
      } @tiles_houses;
    }

  }

  method end_turn () {
    $self->ui->flush_message();

    my $last_player = $self->current_player;
    $last_player->actions({});

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

    $self->ui->add_message("Next player: " . $self->current_player->name . "\n");
    $self->ui->flush_message;
  }

  method status ( Opoly::Player $input_player? ) {
    my @players = defined $input_player ? ($input_player) : @{ $self->players };
    $self->ui->add_message( "------  Player Status  ------\n");

    foreach my $player (@players) {
      $self->ui->add_message( $player->status );
    }

    $self->ui->flush_message;
  }

}

