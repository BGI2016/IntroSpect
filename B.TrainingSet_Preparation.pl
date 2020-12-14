#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use List::Util qw/sum/;

my $outdir;
my $gcdir;
my %hash;
my $prefix;
my $current_path=$ENV{"PWD"};
my $usage = "\n\n$0 [options] \n

Usage: perl $0 -gcdir gcdir -outdir outdir -prefix prefix

Options:

	-gcdir			gibbscluster result directory
	-outdir			output dir
	-prefix			prefix
	-help			Show this message

";

GetOptions(
	'gcdir=s'				=>\$gcdir,
	'outdir=s'				=>\$outdir,
	'prefix=s'				=>\$prefix,
	help					=> sub { pod2usage($usage); },
) or die($usage);

unless($gcdir){
    die "Provide a file to perform training set preparation, -gcdir <gcdir> -outdir <outdir> -prefix <prefix>" , $usage;
}
$gcdir="$current_path/$gcdir" unless($gcdir=~/^\//);



open IM, "<$gcdir/images/gibbs.KLDvsClusters.tab" or die "Can not open $gcdir/images/gibbs.KLDvsClusters.tab:$!\n";
<IM>;
my $sum;
my $maxKLD=0;
my $bestCluster=1;
while(<IM>){
	chomp;
	my @inf = split(/\t/,$_);
	$sum = sum @inf - $inf[0];
	if($maxKLD < $sum){
		$maxKLD = $sum;
		$bestCluster = $inf[0];
	}
}
close IM;

open CL, "<$gcdir/res/gibbs.${bestCluster}g.ds.out" or die "Can not open $gcdir/res/gibbs.${bestCluster}g.ds.out:$!\n";
open OUT,">$outdir/$prefix.trainingSet.txt" or die "Can not open $outdir/$prefix.trainingSet.txt:$!\n";

<CL>;
while(<CL>){
	chomp;
	my @inf = split(/\s+/,$_);
	print $inf[3]."\n";
	print OUT join("\t","HUMAN","HUMAN","class-1",$prefix."_gibbs".$inf[1],"YES",$inf[3],length($inf[3]))."\n";
}

close OUT;
close CL;
