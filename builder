#!/usr/bin/perl
#   Used in makefile to make veicteoir.db
#
#   Not installed as part of package, only used for development
use strict;
use warnings;

use Lingua::GA::Gramadoir;

binmode STDOUT, ":encoding(iso-8859-1)";
binmode STDERR, ":encoding(iso-8859-1)";
binmode STDIN, ":bytes";

# Irish tokenizer works sufficiently well on English sentences too
my $gr = new Lingua::GA::Gramadoir;

my %alltokes;
my %stopwords;

open(STOPS, "<:bytes", 'stoplist') or die "Could not open stop word file.\n";
while (<STOPS>) {
	chomp;
	$stopwords{$_}++;
}
close STOPS;

while (<STDIN>) {
	chomp;
	my ( $tag, $sentence ) = m/^([^ ]+) (.*)$/;
	my $tokes = $gr->tokenize($sentence);
	foreach (@$tokes) {
		if (/../) {
			tr/A-Z¡…Õ”⁄/a-z·ÈÌÛ˙/;
			$alltokes{$_} .=" $tag" unless (exists($stopwords{$_}));
		}
	}
}

print "$_$alltokes{$_}\n" foreach (keys %alltokes);
