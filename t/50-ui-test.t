use strict;
use warnings;

use Test::More;

use_ok('Opoly::UI::Test');

my $ui = Opoly::UI::Test->new();
isa_ok( $ui, 'Opoly::UI');

{
  # test inform
  my $inform = 'Testing Testings 1 2 3';

  $ui->inform( $inform );
  is( $ui->message, $inform, 'inform collects message in message property' );

  $ui->clear;
  is( $ui->message, '', 'clear removes message' );
}

{
  #test input
  my $question = 'Say I do';
  my $answer = 'I do';

  $ui->user_input( $answer );
  my $returned = $ui->input( $question );
  is( $ui->message, $question, 'input collects question in message property' );
  is( $returned, $answer, 'input returns user_input property' );

  $ui->clear;
  is( $ui->user_input, '', 'clear removes user_input' );
}

{
  #test choice
  my $choices = [qw/Yes No/];
  my $choice = 'Yes';
  my $question = 'ORLY?';

  $ui->user_input( $choice );
  my $returned = $ui->choice( $choices, $question );
  is( $ui->message, $question, 'choice collects question in message property' );
  is( $returned, $choice, 'choice returns choice put in user_input');

  $ui->clear;

  my $bad_choice = 'CHEEZ';
  $ui->user_input( $bad_choice );
  eval{ $ui->choice( $choices, $question ) };

  like( $@, qr/$bad_choice/, 'choice throws an exception on a bad choice in user_input' );

  $ui->clear;
}

done_testing;
