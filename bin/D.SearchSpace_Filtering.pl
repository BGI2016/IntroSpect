#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Pod::Usage;
use Cwd 'abs_path';
use feature qw(say);
use POSIX qw(ceil log10);
use List::Util qw(sum max);
use File::Spec;
my $path_curf = File::Spec->rel2abs(__FILE__);
my ($vol, $dirs, $file) = File::Spec->splitpath($path_curf);

my $pep;
my $outdir;
my $ss;
my $pssm;
my $minLen;
my $maxLen;
my $cutoff;
my %hash;
my $prefix;
my $current_path=$ENV{"PWD"};
my $usage = "\n\n$0 [options] \n

Usage: perl $0 -ss ss -outdir outdir -ssprefix ssprefix -pssm	pssm -outprefix outprefix

Options:

	-pep			input high confidence peptide sequences
	-ss			XXX.ss generated by DB2SS.pl
	-outdir			outdir
	-pssm			pssmfile.list generated by D.Motif_Learning.pl
	-minLen			min length of peptides, int [default:9]
	-maxLen			max length of peptides, int [default:11]
	-cutoff			PSSM score cutoff, float [default:0.3]
	-prefix			output file prefix
	-help			Show this message

";

GetOptions(
	'pep=s'					=>\$pep,
	'ss=s'					=>\$ss,
	'outdir=s'				=>\$outdir,
	'pssm=s'				=>\$pssm,
	'minLen=i'				=>\$minLen,
	'maxLen=i'				=>\$maxLen,
	'cutoff'				=>\$cutoff,
	'prefix=s'				=>\$prefix,
	help					=> sub { pod2usage($usage); },
) or die($usage);

unless($pep){
    die "Provide a peptide sequences file to perform search space filtering, -ss <ss> -outdir <outdir> -prefix <prefix> -pssm <pssm>" , $usage;
}
$pep="$current_path/$pep" unless($pep=~/^\//);

unless($ss){
    die "Provide a search space list file to perform search space filtering, -ss <ss> -outdir <outdir> -prefix <prefix> -pssm <pssm>" , $usage;
}
$ss="$current_path/$ss" unless($ss=~/^\//);

unless($pssm){
    die "Provide a pssm file to perform search space filtering, -ss <ss> -outdir <outdir> -prefix <prefix> -pssm <pssm>" , $usage;
}
$pssm="$current_path/$pssm" unless($pssm=~/^\//);

unless($outdir){
    die "Provide a outdir to perform search space filtering, -ss <ss> -outdir <outdir> -prefix <prefix> -pssm <pssm>" , $usage;
}
$outdir="$current_path/$outdir" unless($outdir=~/^\//);

#default parameters
$minLen=9 unless(defined $minLen);
$maxLen=11 unless(defined $maxLen);
$cutoff=0.3 unless(defined $cutoff);
my $score_script = "$dirs/E.Score_Calculation.pl";

#get the clusterGroup and Length pair
my %pssm_valid;
my %pssm_hash;
open PS,"<$pssm" or die "Can not open $pssm:$!\n";
while(<PS>){
	chomp;
	my @inf=split(/\s+/,$_);
	$pssm_valid{$inf[2]}{$inf[1]}=1;
	$pssm_hash{"$inf[1]:$inf[2]"} = $inf[0];
}
close PS;

#get the searchSpaceFile and Length pair
my %ss_valid;
open SS,"<$ss" or die "Can not open $ss:$!\n";
while(<SS>){
	chomp;
	my @inf=split(/\t/,$_);
	if(!exists $ss_valid{$inf[1]}){
		$ss_valid{$inf[1]}=[$inf[0]];
	}
	else{
		push @{$ss_valid{$inf[1]}}, $inf[0];
	}
}
close SS;


#calculation the peptide score
open OUT,">$outdir/$prefix.MIDS.fasta" or die "Can not open $outdir/$prefix.MIDS.fasta:$!\n";
foreach my $key(keys %ss_valid){
	my $len=$key;
	foreach my $keyB2(keys %{$pssm_valid{$key}}){
		my $clusterGroup=$keyB2;
		open SC,">$outdir/$clusterGroup.${len}mer.txt" or die "Can not open $outdir/$clusterGroup.${len}mer.txt:$!\n";
		if(exists $pssm_hash{"$clusterGroup:$len"}){
			foreach my $ssfile(@{$ss_valid{$key}}){
				my @result = `perl $score_script $ssfile $pssm_hash{"$clusterGroup:$len"} $clusterGroup $len`;
				print SC @result;
			}
		}
		else{
			print STDERR "PSSMHCpan could not predict $clusterGroup with the length of $len.\n";
		}
		close SC;
		open IN,"<$outdir/$clusterGroup.${len}mer.txt" or die "Can not open $outdir/$clusterGroup.${len}mer.txt:$!\n";
		while(<IN>){
			chomp;
			my @inf=split(/\t/,$_);
			if($inf[3]>=$cutoff){
				print OUT ">".$clusterGroup."_".$len."mer_".$inf[3]."_".$inf[2]."\n".$inf[2]."\n";
			}
		}
		close IN;
	}
}

open PEP, "<$pep" or die "Can not open $pep:$!\n";
my $n=0;
while(<PEP>){
	chomp;
	$n++;
	my @inf=split(/\t/,$_);
	my $len=length($inf[0]);
	print OUT ">FirstRound_".$len."mer_".$n."\n".$inf[0]."\n";
}
close PEP;
close OUT;
