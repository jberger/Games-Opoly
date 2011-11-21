use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Opoly::UI::Test;

use_ok('Opoly::Dice');
my $dice = Opoly::Dice->new;
isa_ok( $dice, 'Opoly::Dice' );

{
  my %rolls;
  my $sum;

  map { $rolls{$_}++ } map { $dice->roll_one } (1..6000);

  is_deeply( [sort keys %rolls], [ 1 .. 6 ], 'Die rolls 1-6' );

  $sum += $_ for values %rolls;
  is( $sum, 6000, 'total number of dice thrown is correct' );

  my @test = map { $_ > 800 and $_ < 1200 } values %rolls;
  is_deeply( \@test, [ map { 1 } (1..6) ], 'All values thrown between 800 and 1200 times (6000 total)' );
}

{
  my %rolls;
  my $sum;

  map { $rolls{$_}++ } map { $dice->roll_two } (1..6000);

  is_deeply( [sort keys %rolls], [ 1 .. 6 ], 'Die rolls 1-6' );

  $sum += $_ for values %rolls;
  is( $sum, 12000, 'total number of dice thrown is correct' );

  my @test = map { $_ > 1600 and $_ < 2400 } values %rolls;
  is_deeply( \@test, [ map { 1 } (1..6) ], 'All values thrown between 1600 and 2400 times (6000 total rolls of two dice)' );
}

{
  my $ui = Opoly::UI::Test->new();
  my $loaded = Opoly::Dice::Loaded->new( ui => $ui );
  isa_ok( $loaded, 'Opoly::Dice' );
  isa_ok( $loaded, 'Opoly::Dice::Loaded' );

  $ui->user_input('26');
  is_deeply( [$loaded->roll_two], [2, 6], 'Loaded dice respond to user input');
}

done_testing;

