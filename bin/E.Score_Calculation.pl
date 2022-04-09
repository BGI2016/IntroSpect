#!/usr/bin/perl
use strict;

die "Scoring peptides from input protein sequence use PSSM\n
	perl $0 <protein> <pssm> <allele> <length>\n" if(@ARGV != 4);
my ($protein, $pssm, $allele, $length) = @ARGV;

my @lib = ('A', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'Y');

my %pssm;
local $/ = "\n>";
open(FH, $pssm) || die $!;
while(<FH>)
{
	chomp;
	s/^>//;
	my @tmp = split /\n/;
	die "Wrong PSSM, number of amino acid unequal to 20.\n" if($#tmp != 20);
	for my $i (1..$#tmp)
	{
		@{$pssm{$tmp[0]}{$lib[$i-1]}} = split /\s+/, $tmp[$i];
	}
}
close FH;
local $/ = "\n";

my $max = 0.8;
my $min = 0.8 * (1 - log(50000) / log(500));
open(FH, $protein) || die $!;
while(my $content = <FH>)
{
	$content =~ s/\n//g;
        
	my $pssm_id = $allele." ".$length;
        if(exists $pssm{$pssm_id})
	{
		my $score = 0;
		for my $i (0..length($content)-1)
		{
			my $char = substr($content, $i, 1);
			$score += $pssm{$pssm_id}{$char}[$i];
		}
		$score = $score / $length;
	        print "PSSMHCpan\t$allele\t$content\t$score\n" ;
        }
}
close FH;
