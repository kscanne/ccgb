#!/usr/bin/perl

use strict;
use warnings;

my %freqhash;
my %lenhash;
my $N = 0;

# used by shell script "mt" to postprocess output of ppfaigh

open (FREQFILE, '/usr/local/share/crubadan/en/FREQ') or die "Error opening English frequencies: $!\n";

while (<FREQFILE>) {
	chomp;
	my ($freq,$word) = split;
	$word =~ tr/A-Z/a-z/;
	$freq++;  # smoothing
	$freqhash{$word} = 0 unless (exists($freqhash{$word}));
	$freqhash{$word} += $freq;
	$N += $freq;
}
close FREQFILE;

# actually store probability that a random word is NOT the key
foreach (keys %freqhash) {
	$freqhash{$_} = 1 - $freqhash{$_}/$N;
}

open (LENFILE, '/home/kps/gaeilge/corpas/corpas/lengths.txt') or die "Error opening sentence length file: $!\n";

while (<LENFILE>) {
	chomp;
	my ($tag,$len) = split;
	$lenhash{$tag} = $len;
}
close LENFILE;

my %candidates;

while (<STDIN>) {
	chomp;
	if (/^(\S+) (.+)$/) {
		my $word = $1;
		my @tags = split / /,$2;
		my @engtags = grep(/-b:/, @tags);
		my %tags;
		$tags{$_}++ foreach (@engtags);  # must make unique!
		my $prob = 1 - 1/$N;
		if (exists($freqhash{$word})) {
			$prob = $freqhash{$word};
		}
		foreach my $tag (keys %tags) {
			if ($lenhash{$tag} == 0) {
				print STDERR "Warning: word $word apparently found in sentence with no words or stopwords only: $tag\n";
			}
			else {
				$candidates{$tag} = 0 unless (exists($candidates{$tag}));
				$candidates{$tag} += -log(1 - $prob**$lenhash{$tag});
			}
		}
	}
	else {
		my $count = 0;
		foreach (sort {$candidates{$b} <=> $candidates{$a}} keys %candidates) {
			print "$_ $candidates{$_}\n";
			$count++;
			last if ($count == 10);
		}
		%candidates = ();
		print "\n";
	}
}

exit 0;
