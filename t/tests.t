#!/usr/bin/perl

use strict;
use warnings;

BEGIN {

  use Test::More tests => 55;

  use_ok( 'DateTime' );
  use_ok( 'DateTimeX::Duration::SkipDays' );
  use_ok( 'DateTime::Event::Holiday::US' );

}

my ( $skip_days, $sd, $span, $skipped, %skipped_days, $iter, $expected_end );

# Make sure empty new() returns valid object.
$sd = DateTimeX::Duration::SkipDays->new();
isa_ok( $sd, 'DateTimeX::Duration::SkipDays', 'empty new returns valid object' );

# Make sure invalid references cause death.
eval{ $sd = DateTimeX::Duration::SkipDays->new([]) };
like( $@, qr/Must pass nothing or a reference to a hash to new/, 'array ref dies correctly' );

eval{ $sd = DateTimeX::Duration::SkipDays->new(\$skipped) };
like( $@, qr/Must pass nothing or a reference to a hash to new/, 'scalar ref dies correctly' );

eval{ $sd = DateTimeX::Duration::SkipDays->new(sub{}) };
like( $@, qr/Must pass nothing or a reference to a hash to new/, 'code ref dies correctly' );

# Make sure 'add' included in call to new is ignored.
$sd = DateTimeX::Duration::SkipDays->new({ 'add' => '1' });
isa_ok( $sd, 'DateTimeX::Duration::SkipDays', 'hash with add returns valid object' );

# Make sure unkown key is ignored.
$sd = DateTimeX::Duration::SkipDays->new({ 'badkey' => '1' });
isa_ok( $sd, 'DateTimeX::Duration::SkipDays', 'hash with bad key returns valid object' );

# Make sure start_date doesn't work with anything but a DateTime object.
eval{ $sd->start_date( 'monkey' ) };
like( $@, qr/Must pass a DateTime object to start/, 'start_date dies correctly' );

# Make sure parse_dates dies with anything but a scalar.
eval{ $sd->parse_dates( {} )};
like( $@, qr/Expected scalar/, 'parse_dates dies correctly' );

# Make sure parse dates bad formats correctly.
$sd->parse_dates( 'bad format' );
my $bf = $sd->bad_formats;
isa_ok( $bf, 'ARRAY' );
is( $bf->[0], 'bad format' );

my $skip_weekends  = q(RRULE:FREQ=WEEKLY;BYDAY=SA,SU);

#       July 2011             August 2011
# Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa
#                 1  2      1  2  3  4  5  6
#  3  4  5  6  7  8  9   7  8  9 10 11 12 13
# 10 11 12 13 14 15 16  14 15 16 17 18 19 20
# 17 18 19 20 21 22 23  21 22 23 24 25 26 27
# 24 25 26 27 28 29 30  28 29 30 31
# 31

my $skip_x_days    = 30;
my $start_date     = DateTime->new( 'year' => 2011, 'month' => 7, 'day' => 1 );
my $start_date_ymd = $start_date->ymd;

# Skip Nothing
my $temp = $skip_x_days;
$skip_x_days = 0;

$sd = DateTimeX::Duration::SkipDays->new( { 'start_date' => $start_date } );

if ( keys %{ $sd->bad_format } ) {

  fail( 'This should never happen! Problem parsing format(s)' );
  my %bf = %{ $sd->bad_format };
  diag( $_ ) for map { "Bad format: $_ ($bf{ $_ })" } keys %bf;

}

# Both DateTime::Duration::SkipDays and DateTime should return the same date
# when adding 0 days and skipping nothing.

my $dt = $start_date->clone;
$dt->add( 'days' => $skip_x_days );

( $span, $skipped ) = $sd->add( $skip_x_days );

check_date( $span->start->ymd, $start_date_ymd, 'Skip Nothing - Start' );
check_date( $span->end->ymd,   $start_date_ymd, "Skip Nothing (Skip $skip_x_days Days) - End" );

$skip_x_days = $temp;

# Both DateTime::Duration::SkipDays and DateTime should return the same date
# when adding days and skipping nothing.

$dt = $start_date->clone;
$dt->add( 'days' => $skip_x_days );
my $dt_ymd = $dt->ymd;

( $span, $skipped ) = $sd->add( $skip_x_days );

check_date( $span->start->ymd, $start_date_ymd, 'Skip Nothing - Start' );
check_date( $span->end->ymd,   $dt_ymd,         "Skip Nothing (Skip $skip_x_days Days) - End" );

# Skip Independence Day
$skip_days = q(Independence Day);

$sd = make_sd( $start_date, $skip_days );

( $span, $skipped ) = $sd->add( $skip_x_days );

#       July 2011             August 2011
# Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa
#                 1. 2    . 1  2  3  4  5  6
#. 3  4. 5. 6. 7. 8. 9   7  8  9 10 11 12 13
#.10.11.12.13.14.15.16  14 15 16 17 18 19 20
#.17.18.19.20.21.22.23  21 22 23 24 25 26 27
#.24.25.26.27.28.29.30  28 29 30 31
#.31
#
check_date( $span->start->ymd, $start_date_ymd, 'Skip Independence Day - Start' );
check_date( $span->end->ymd,   '2011-08-01',    "Skip Independence Day - (Skip $skip_x_days Days) - End" );

%skipped_days = ( '2011-07-04' => 1 );

check_skipped_days( $skipped->iterator, \%skipped_days );

# Skip weekends

$sd = make_sd( $start_date, $skip_weekends );

( $span, $skipped ) = $sd->add( $skip_x_days );

check_date( $span->start->ymd, $start_date_ymd, 'Skip weekends - Start' );
check_date( $span->end->ymd,   '2011-08-12',    "Skip weekends - (Skip $skip_x_days Days) - End" );

#       July 2011             August 2011
# Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa
#                 1  2    . 1. 2. 3. 4. 5  6
#  3. 4. 5. 6. 7. 8  9   7. 8. 9.10.11.12 13
# 10.11.12.13.14.15 16  14 15 16 17 18 19 20
# 17.18.19.20.21.22 23  21 22 23 24 25 26 27
# 24.25.26.27.28.29 30  28 29 30 31
# 31

%skipped_days = ( '2011-07-02' => 1, '2011-07-03' => 1, '2011-07-09' => 1, '2011-07-10' => 1, '2011-07-16' => 1, '2011-07-17' => 1, '2011-07-23' => 1, '2011-07-24' => 1, '2011-07-30' => 1, '2011-07-31' => 1, '2011-08-06' => 1, '2011-08-07' => 1, );

check_skipped_days( $skipped->iterator, \%skipped_days );

# Skip Independence Day, weekends and an arbitrary day.

$skip_days = qq(

Independence Day
$skip_weekends
7/22

);

$sd = make_sd( $start_date, $skip_days );

( $span, $skipped ) = $sd->add( $skip_x_days );

check_date( $span->start->ymd, $start_date_ymd, 'Skip combo - Start' );
check_date( $span->end->ymd,   '2011-08-16',    "Skip combo - (Skip $skip_x_days Days) - End" );

#       July 2011             August 2011
# Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa
#                 1  2    . 1. 2. 3. 4. 5  6
#  3  4. 5. 6. 7. 8  9   7. 8. 9.10.11.12 13
# 10.11.12.13.14.15 16  14.15.16 17 18 19 20
# 17.18.19.20.21 22 23  21 22 23 24 25 26 27
# 24.25.26.27.28.29 30  28 29 30 31
# 31

%skipped_days = ( '2011-07-02' => 1, '2011-07-03' => 1, '2011-07-04' => 1, '2011-07-09' => 1, '2011-07-10' => 1, '2011-07-16' => 1, '2011-07-17' => 1, '2011-07-22' => 1, '2011-07-23' => 1, '2011-07-24' => 1, '2011-07-30' => 1, '2011-07-31' => 1, '2011-08-06' => 1, '2011-08-07' => 1, '2011-08-13' => 1, '2011-08-14' => 1, );

check_skipped_days( $skipped->iterator, \%skipped_days );

sub make_sd {

  my ( $start_date, $parse_dates ) = @_;

  $sd = DateTimeX::Duration::SkipDays->new( { 'start_date' => $start_date, 'parse_dates' => $parse_dates, } );

  if ( keys %{ $sd->bad_format } ) {

    fail( 'Problem parsing format(s)' );
    my %bf = %{ $sd->bad_format };
    diag( $_ ) for map { "Bad format: $_ ($bf{ $_ })" } keys %bf;

  }

  return $sd;

}

sub check_date {

  my ( $got, $expected, $note ) = @_;

  ok( $got eq $expected, $note )
    or diag( "Got $got; expected $expected" );

}

sub check_skipped_days {

  my ( $iter, $skipped_days ) = @_;

  while ( my $dt = $iter->next ) {

    my $dt_ymd = $dt->min->ymd;
    ok( exists $skipped_days->{ $dt_ymd }, "Skipped $dt_ymd" );
    delete $skipped_days->{ $dt_ymd };

  }

  if ( keys %$skipped_days ) {

    fail( 'Not all expected days skipped' );
    diag( $_ ) for keys %$skipped_days;

  } else {

    pass( 'All expected days skipped' );

  }
} ## end sub check_skipped_days
