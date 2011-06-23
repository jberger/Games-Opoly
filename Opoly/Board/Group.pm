use MooseX::Declare;

class Opoly::Board::Group {

  use Opoly::Board::Tile;

  has 'name' => ( isa => 'Str', is => 'ro', required => 1 );
  has 'tiles' => ( isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub{ [] });

  method add_tile (Opoly::Board::Tile $tile) {
    push @{ $self->tiles }, $tile;
  }

}

class Opoly::Board::Group::Ownable
  extends Opoly::Board::Group {

  use List::MoreUtils qw/all uniq/;

  has '+tiles' => (isa => 'ArrayRef[Opoly::Board::Tile::Ownable]');

  method monopoly () {
    my @tiles = @{ $self->tiles };

    # check that all tiles have owners
    return 0 unless all { $_->has_owner } @tiles;

    # check that all tiles have the same owner
    return 0 unless ( 1 == uniq map { $_->owner } @tiles);

    #TODO add override if any mortgaged.

    return 1;
  }

  method number_owned_by ( Opoly::Player $player ) {
    my $num = grep { defined $_ and $_ == $player } map { $_->owner } @{ $self->tiles };

    return $num;
  }

}

class Opoly::Board::Group::Property 
  extends Opoly::Board::Group::Ownable {

  has 'houses_cost' => ( isa => 'Num', is => 'ro', required => 1 );
  has '+tiles' => ( isa => 'ArrayRef[Opoly::Board::Tile::Property]');

}

