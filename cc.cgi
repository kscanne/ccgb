#!/usr/bin/perl -wT

use strict;
use CGI;

$CGI::DISABLE_UPLOADS = 1;
$CGI::POST_MAX        = 1024;

$ENV{PATH}="/bin:/usr/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

my $SEARCHENGINE = '/usr/local/bin/ccweb';
my @shellargs;
my $q = new CGI;
my( $ionchur ) = $q->param( "foirm_ionchur" ) =~ /^(["'áéíóúÁÉÍÓÚ\w\s,.!?-]+)$/;
my( $hits ) = $q->param( "hits" ) =~ /^([0-9]+)$/;
my( $format ) = $q->param( "format" ) =~ /^([a-z]+)$/;

my @allargs = $q->param;
push @shellargs, "--max=$hits";
push @shellargs, "--html"   if ( $format eq "html" );
push @shellargs, "--mutate" if ( "@allargs" =~ /mutate/ );

while ($ionchur =~ m/("[^"]+"|[^" ]\S+)/g) {
	my $term = $1;
	$term =~ s/^"//;
	$term =~ s/"$//;
	push @shellargs, $term;
}


local *PIPE;

print $q->header( "text/$format" );     # http headers, not html headers!

#unless ( $ionchur ) {
#print "<a href=\"http://borel.slu.edu/corpas/\">Corpas Comhthreomhar</a>: carachtair neamhbhailí sa théacs";
#exit;
#}

$ionchur =~ s/'/\'/g;

my $pid = open PIPE, "-|";
die "Fork failed: $!" unless defined $pid;
unless ( $pid ) {
	     exec $SEARCHENGINE, @shellargs or die "Can't open pipe: $!";
	}

print while <PIPE>;
close PIPE;
