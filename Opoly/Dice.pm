use MooseX::Declare;

class Opoly::Dice {

  method roll_two () {
    return map { $self->roll_one } (0 .. 1);
  }

  method roll_one () {
    return 1 + int rand(6);
  }

}

class Opoly::Dice::Loaded 
  extends Opoly::Dice {

  use List::MoreUtils qw/all/;

  has 'ui' => (isa => 'Opoly::UI', is => 'ro', required => 1); 

  override roll_two () {
    my $response = $self->ui->input("-- Input two numbers");
    my @nums = split(//, $response);

    unless ( (all { /\d{1}/ } @nums) and (@nums > 1) ) {
      $self->ui->add_message("-- Could not understand response!\n");
      @nums = $self->roll_two();
    }

    return @nums;
  }

}
