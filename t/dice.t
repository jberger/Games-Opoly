use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('Opoly::Dice');
my $dice = Opoly::Dice->new;

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

done_testing;

