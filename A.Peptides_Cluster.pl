#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

my $outdir;
my $GCmotifLen;
my $GCmotif;
my $minLen;
my $maxLen;
my $gc;
my $file;
my %hash;
my $prefix;
my $current_path=$ENV{"PWD"};
my $usage = "\n\n$0 [options] \n

Usage: perl $0 -file infile -outdir outdir -prefix prefix

Options:

	-file				input sequences, string
	-outdir				output dir, string
	-minLen				min length of peptides, int [default:9]
	-maxLen				max length of peptides, int [default:11]
	-prefix				prefix of output file, string [default:MIDS.test]
	-GCmotif			number of possible MHC specificities, int-int [default:1-6]
	-GCmotifLen			motif length [default:9]
	-gc				gibbscluster path, string
	-help				Show this message

";

GetOptions(
	'file=s'				=>\$file,
	'outdir=s'				=>\$outdir,
	'prefix=s'				=>\$prefix,
	'minLen=i'				=>\$minLen,
	'maxLen=i'				=>\$maxLen,
	'GCmotif=s'				=>\$GCmotif,
	'GCmotifLen=i'			=>\$GCmotifLen,
	'gc=s'					=>\$gc,
	help					=> sub { pod2usage($usage); },
) or die($usage);

unless($file){
    die "Provide a file to perform peptides gibbs clustering, -file <infile> -outdir <outdir> -gc <gibbscluster path>" , $usage;
}
$file="$current_path/$file" unless($file=~/^\//);

unless($outdir){
    die "Provide a outdir to perform motif learning, -file <infile> -outdir <outdir> -gc <gibbscluster path>" , $usage;
}
$outdir="$current_path/$outdir" unless($outdir=~/^\//);

unless($gc){
    die "Provide gibbscluster path to perform motif learning, -file <infile> -outdir <outdir> -gc <gibbscluster path>" , $usage;
}
$gc="$current_path/$gc" unless($gc=~/^\//);

#default parameters
$minLen=9 unless(defined $minLen);
$maxLen=11 unless(defined $maxLen);
$GCmotif="1-6" unless(defined $GCmotif);
$GCmotifLen=9 unless(defined $GCmotifLen);
$prefix="MIDS.test" unless(defined $prefix);

if ($file=~/\.gz/){open IN,"zcat $file |" or die "Cannont open $file:$!\n";}else{   ##different from original version!
open IN,"<$file" or die "Can not open $file:$!\n";}



open OUT,">$outdir/$prefix.${minLen}-${maxLen}mer.txt" or die "Can not open $outdir/$prefix.${minLen}-${maxLen}mer.txt:$!\n";


while(<IN>){
	chomp;
	my @inf=split(/\s+/,$_);
	my $len=length($inf[0]);
	if(($len>=$minLen) && ($len<=$maxLen)){
		print OUT $inf[0]."\n";
	}
}

close IN;
close OUT;

my $insertion=$minLen-$GCmotifLen;
my $deletion=$maxLen-$GCmotifLen;

system("$gc -f $outdir/$prefix.${minLen}-${maxLen}mer.txt -g $GCmotif -P $prefix.${minLen}-${maxLen}mer -R $outdir/$prefix.${minLen}-${maxLen}mer -C -T -j 2 -l $GCmotifLen -S 5 -I $insertion -D $deletion -k 2");


