use MooseX::Declare;
use Method::Signatures::Modifiers;

class Games::Opoly::Dice {

  method roll_two () {
    return map { $self->roll_one } (0 .. 1);
  }

  method roll_one () {
    return 1 + int rand(6);
  }

}

class Games::Opoly::Dice::Loaded 
  extends Games::Opoly::Dice {

  use List::MoreUtils qw/all/;

  has 'ui' => (isa => 'Games::Opoly::UI', is => 'ro', required => 1); 

  override roll_two () {
    my $response = $self->ui->input("-- Input two numbers");
    my @nums = split(//, $response);

    unless ( (all { /\d{1}/ } @nums) and (@nums > 1) ) {
      $self->ui->inform("-- Could not understand response!\n");
      @nums = $self->roll_two();
    }

    return @nums;
  }

}
