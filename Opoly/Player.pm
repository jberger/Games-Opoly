use MooseX::Declare;

class Opoly::Player {

  use Opoly::Board::Tile;

  has 'name' => (isa => 'Str', is => 'ro', required => 1);
  has 'location' => (isa => 'Opoly::Board::Tile', is => 'rw');
  has 'money' => (isa => 'Num', is => 'rw', default => 1500);
  has 'properties' => (isa => 'ArrayRef[Opoly::Board::Tile]', is => 'rw', default => sub { [] } );
  has 'num_roll' => (isa => 'Num', is => 'rw', default => 0);
  has 'choices' => (isa => 'HashRef', is => 'rw', default => sub{ {} });

  method status () {
    my $message = "Name: " . $self->name . "\n";
    $message .= '-- Money: $' . $self->money . "\n";
    $message .= "-- Properties: \t" . join("\n\t\t", map { $_->name } @{$self->properties}) . "\n";
  }

  method remove_choice (Str $key_stem) {
    my @remove_keys = grep { /^$key_stem/i } keys %{ $self->choices };

    die "Key to remove not uniquely determined" if (@remove_keys > 1);
    return 0 if (@remove_keys == 0);

    my %choices = %{$self->choices};
    delete $choices{$remove_keys[0]};
    $self->choices(\%choices);
  }

}


