#!/usr/bin/perl

use strict;
use warnings;
use DB_File;
use Fcntl;
use Locale::PO;
use Lingua::EN::Sentence qw( get_sentences );
use Lingua::EN::Tagger;
use Text::Diff;
use File::Copy;

if (@ARGV == 0) {
	die "Usage: $0 COMHAIDPO\n";
}

my %veic;
my %corpas;
my %lemmat_wordlist;
my %lemmat_rules;
my %stoplist;
my %currentlemmas;
my %freqhash;
my %lenhash;
my @focloir;
my $N = 0;
my $en_tagger = new Lingua::EN::Tagger;

my $vdb = tie %veic, "DB_File", "/usr/local/share/corpas/veicteoir.db", O_RDONLY, 0644, $DB_HASH || die $!;
my $cdb = tie %corpas, "DB_File", "/usr/local/share/corpas/mor.db", O_RDONLY, 0644, $DB_HASH || die $!;
open (STOPS, '/usr/local/share/corpas/stoplist');
while (<STOPS>) {
	chomp;
	$stoplist{$_}++;
}
close STOPS;
open (FREQFILE, '/usr/local/share/crubadan/en/FREQ') or die "Error opening Engli
sh frequencies: $!\n";
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
open (DICT, '/home/kps/gaeilge/diolaim/c/en') or die "Error opening English-Irish dictionary: $!\n";
while (<DICT>) {
	push @focloir,$_ if (/^([^ ]+)  /);
}
close DICT;
readrules('/home/kps/clar/sonrai/rules.bnc');
readirregfile('/home/kps/clar/sonrai/words.bnc');
my $done_p = "";


sub my_warn
{
return 1;
}

sub keep_if_keepable
{
my ($cand) = @_;
if ($cand =~ m/../ && $cand =~ m/[a-z]/) {
	$currentlemmas{$cand}++ unless (exists($stoplist{$cand}));
}
}

# takes input text and fills currentlemmas hash with all lemmas
sub lemmatize
{
	my ($input) = @_;
	my $sentences = get_sentences($input);
	%currentlemmas = ();
	foreach (@$sentences) {
		my $tagged = $en_tagger->add_tags( $_ );
		while ($tagged =~ m/<([^>]+)>([^<]+)<\/[^>]+>/g) {
			my $pos = "\U$1";
			my $word = $2;
			my $lemma=lc($word);
			if ($word=~/[\w\'-]+/) {
			    if (exists $lemmat_wordlist{$pos}{$lemma}) { 
				$lemma=$lemmat_wordlist{$pos}{$lemma};
			    } elsif (exists $lemmat_rules{$pos}) {
				my @rules=@{$lemmat_rules{$pos}};
				my $i=0;
				$_=$lemma;
				do { 
				    if ($rules[$i]) {
					eval($rules[$i]) ;
					warn "error in $word: $rules[$i]: $@" if $@;
				    }
				} until (($_ ne $lemma) or ($i++>$#rules));
				$lemma=$_;
			    }
			} else { #punctuation marks
			    if ($pos=~/\W+/) {$pos='PUN'};
			};
			$pos=~s/PUNCT/PUN/;
			$pos=~s/CS22/IN22/;
			keep_if_keepable("\L$word");
			keep_if_keepable($lemma);
		}
	}
}



sub userinput {
	my ($prompt) = @_;
	print "$prompt: ";
	$| = 1;          # flush
	$_ = getc;
	my $ans = $_;
	$_ = getc while (m/[^\n]/);
	return $ans;
}


# called right after lemmatize, so %currentlemmas is full
# job of this function is to write out /tmp/focloirin.txt hits file
sub get_focloir_hitz
{
	open OUTPUT, ">/tmp/focloirin.txt";
	print OUTPUT "English-Irish dictionary\n";
	foreach my $word (keys %currentlemmas) {
		print OUTPUT $_ foreach (grep(/^$word  /, @focloir));
	}
	close OUTPUT;
}

# called right after lemmatize, so %currentlemmas is full
# job of this function is to write out /tmp/fuzzies.po hits file
sub get_best_corpus_hitz
{
	my %candidates;
	foreach my $word (keys %currentlemmas) {
		$word =~ s/$/\x{000}/;
		if (exists($veic{$word})) {
			my $vec = $veic{$word};
			$vec =~ s/.$//;
			my @tags = split / /,$vec;
	                my @engtags = grep(/-b:/, @tags);
			my %tags;
			$tags{$_}++ foreach (@engtags);  # must make unique!
			my $prob = 1 - 1/$N;
			$prob = $freqhash{$word} if (exists($freqhash{$word}));
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
	}
	my $count = 1;
	open OUTPUT, ">/tmp/fuzzies.po";
	foreach my $en (sort {$candidates{$b} <=> $candidates{$a}} keys %candidates) {
		print OUTPUT "#: >>F$count<< ($en)\n";
		$en =~ s/$/\x{000}/;
		my $temp = $corpas{$en};
		$temp =~ s/([^\\])"/$1\\"/g;
		$temp =~ s/^/msgid "/;
		$temp =~ s/.$/"/;
		print OUTPUT "$temp\n";
		my $ga = $en;
		$ga =~ s/-b:/:/;
		$temp = $corpas{$ga};
		$temp =~ s/([^\\])"/$1\\"/g;
		$temp =~ s/^/msgstr "/;
		$temp =~ s/.$/"/;
		print OUTPUT "$temp\n";
		$count++;
		last if ($count > 25);
	}
	close OUTPUT;
}

sub vim_translate
{
my ($id) = @_;
my $stripped = $id;
$stripped =~ s/[&~]//g;
lemmatize($stripped);
get_best_corpus_hitz();
get_focloir_hitz();
open OUTPUT, ">/tmp/toedit.po";
print OUTPUT "msgid $id\nmsgstr $id\n";
close OUTPUT;
system 'vim -u /home/kps/.poeditrc -n /tmp/toedit.po';
open INPUT, "</tmp/toedit.po";
my $msgstr_started = '';
my $ans = '';
while (<INPUT>) {
	if (/^msgstr "/) {
		$msgstr_started = 'true';
		s/^msgstr +"//;
		s/"\s*//;
		$ans .= $_;
	}
	else {
		if ($msgstr_started) {
			s/^ *"//;
			s/"\s*//;
			$ans .= $_;
		}
	}
}
close INPUT;
return $ans;
}


# takes a msg, go through all of the UI motions and return the
# hopefully translated msgstr
sub translate_me
{
my ($msg) = @_;
my $ma = $msg->automatic();
my $mc = $msg->comment();
my $mr = $msg->reference();
my $id = $msg->msgid();
print "# $ma\n" if $ma;
print "# $mc\n" if $mc;
print "# $mr\n" if $mr;
print "msgid $id\n" if $id;
my $i='x';
while ($i =~ /^[^1234]/) {
	$i=userinput('(1)translate,(2)skip,(3)copy msgid,(4)exit');
}
if ($i =~ m/^1/) {
	my $temp = vim_translate($id);
	$msg->msgstr($temp);
}
elsif ($i =~ m/^2/) {
	1;  # do nothing
}
elsif ($i =~ m/^3/) {
	$msg->msgstr($msg->msgid());
}
elsif ($i =~ m/^4/) {
	$done_p = 'true';
}
}


#### MAIN STARTS HERE #####
while ($ARGV = shift @ARGV) {
	my $aref;
{

	local $SIG{__WARN__} = 'my_warn';
	$aref = Locale::PO->load_file_asarray($ARGV);
}
	foreach my $msg (@$aref) {
		my $id = $msg->msgid();
		my $str = $msg->msgstr();
		if (defined($id) && defined($str)) {
			if ($str and $id) {
				translate_me($msg) if ($str eq '""');
				last if $done_p;
			}
		}
	}
	Locale::PO->save_file_fromarray('/tmp/temp.po',$aref);
	system 'msgcat /tmp/temp.po > /tmp/temp2.po';
	my $diff = diff $ARGV, '/tmp/temp2.po', { STYLE => "Unified" };
	print $diff;
	my $ok='?';
	while ($ok =~ m/^[^YNyn]/) {
		$ok=userinput('Commit changes (y/n)?');
	}
	copy('/tmp/temp2.po', $ARGV) if ($ok =~ m/^[Yy]/);
}

# untie %corpas;
# untie %veic;
exit 0;


sub readrules {
    my ($input)=@_;
    my $curpos='';
    my $left;
    my $right;
    my $lengthstr;
    open(IN,$input) or die "Can't open file $input\n";
    while (<IN>) {
	s/\#.*//;
#	chomp; the last space is left for deleting rules
	if (/^([\w\$]+)/) {
	    $curpos=$1;
	    $lemmat_rules{$curpos}=[];
	} elsif (($lengthstr,$left,$right)=/\s+([<>\d]*)\s+([\w\'-]+)\s+(\w*)/) {
	    my $nextreplt=1;
	    my $direction;
	    my $length;
	    if (($direction,$length)=$lengthstr=~/([<>])(\d+)/) {
		if ($direction eq '>') {
		    $left="(..)".$left; 
		    $right='$'.$nextreplt.$right;
		    $nextreplt++;
		} elsif ($direction eq '<') {
		    $length--;
		    $left="^(.{1,$length})".$left; 
		    $right='$'.$nextreplt.$right;
		    $nextreplt++;
		} else {
		    print "error: wrong direction in $_ \n" if $_;
		}
	    };
	    if ($left=~/CC/) {
		$left=~s/CC/([^aeiouy])\\1/g;
		$right=~s/C/\$$nextreplt/;
		$nextreplt++;
	    } elsif ($left=~s/([VCR]+)/($1)/) {
		my $phonolog=$1;
		$left=~s/V/[aeiouyr]/g;
		$left=~s/C/[^aeiouy]/g;
		$left=~s/R/r/g;
		$right=~s/$phonolog/\$$nextreplt/;
		$nextreplt++;
	    };
	    my $rule="s/$left\$/$right/";
	    my @rules=@{$lemmat_rules{$curpos}};
	    push @rules, $rule;
	    $lemmat_rules{$curpos}=[@rules];
	} else {
	    print "error: cannot read the rule in $_ \n" if $_=~/\S/;
	}
    }
    close(IN);
}

sub readirregfile {
    my ($input)=@_;
    my $curpos='';
    my $lemma;
    my $word;
    open(IN,$input) or die "Can't open file $input\n";
    while (<IN>) {
	s/\#.*//;
#	chomp; the last space is left for 
	if (/^([\w\$]+)/) {
	    $curpos=$1;
	} elsif (($word,$lemma)=/\s+([\w\'-]+)\s+([\w\'-]*)/) {
	    $lemmat_wordlist{$curpos}{$word}=($lemma)? $lemma : $word;
	} else {
	    print "error: cannot read the word-lemma pair in $_ \n" if $_=~/\S/;
	}
    }
    close(IN);
}
