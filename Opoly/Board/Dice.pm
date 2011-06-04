use MooseX::Declare;

class Opoly::Board::Dice {

  method roll_two () {
    return map { $self->roll_one } (0 .. 1);
  }

  method roll_one () {
    return 1 + int rand(6);
  }

}

class Opoly::Board::Dice::Loaded {

  has 'ui' => (isa => 'Opoly::UI::CLI', is => 'ro', required => 1); 

  method roll_two () {
    
  }

  method roll_one () {

  }

}
