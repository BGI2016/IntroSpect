#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

my $minLen;
my $maxLen;
my $outdir;
my $file;
my $prefix;
my $current_path=$ENV{"PWD"};
my $usage = "\n\n$0 [options] \n

Usage: perl $0 -file infile -outdir outdir -minLen minLen -maxLen -prefix prefix

Options:

	-file			protein database fasta file
	-minLen			min length of peptides [default:9]
	-maxLen			max length of peptides [default:11]
	-outdir			output dir
	-prefix			prefix of outfile [default:MIDS.test]
	-help			Show this message

";

GetOptions(
	'file=s'				=>\$file,
	'minLen=i'				=>\$minLen,
	'maxLen=i'				=>\$maxLen,
	'outdir=s'				=>\$outdir,
	'prefix=s'				=>\$prefix,
	help					=> sub { pod2usage($usage); },
) or die($usage);

unless($file){
    die "Provide a file to perform search space generation from fasta file, -file <infile> -minLen <minLen> -maxLen <maxLen> -outdir <outdir> -prefix <prefix>" , $usage;
}
$file="$current_path/$file" unless($file=~/^\//);

unless($outdir){
    die "Provide a file to perform search space preparation from fasta file, -file <infile> -minLen <minLen> -maxLen <maxLen> -outdir <outdir> -prefix <prefix>" , $usage;
}
$outdir="$current_path/$outdir" unless($outdir=~/^\//);
system("mkdir -p $outdir");

#default parameters
$minLen=9 unless(defined $minLen);
$maxLen=11 unless(defined $maxLen);
$prefix="MIDS.test" unless(defined $prefix);

if($minLen > $maxLen){
	die "minLen shounld not exceed maxLen.", $usage;
}

#open file
if ($file=~/\.gz/){open IN,"zcat $file |" or die "Cannont open $file:$!\n";}else{   ##different from original version!
open IN,"<$file" or die "Can not open $file:$!\n";}

my $n = 0;
my $seq = "";
my $last_col;
my %hash;
my $seq_splited;
my $len;

while(<IN>){
	chomp;
	if(/^>/){
		#record processing sequences number and print it
		$n++;
		if($n % 1000==0){
			print "$n sequences has been processed!\n";
		}
		#start sequence processing when get the last sequence
		for(my $kmer=$minLen;$kmer<=$maxLen;$kmer++){
			if($seq ne ""){
				$len = length($seq);
				#directly record short sequences
				if($len <= $kmer){
					$hash{$kmer}{$seq}++;
				}
				#record long sequences after processing
				else{
					for(my $i=0;$i<=$len - $kmer;$i++){
						$seq_splited = substr($seq,$i,$kmer);
						$seq_splited = uc($seq_splited);
						#skip the sequences contain some special AA characters
						if($seq_splited=~/B|J|V|O|U|X|Z/){
							next;
						}
						else{
							$hash{$kmer}{$seq_splited}++;
						}
					}
				}
				$seq = "";
			}
			#skip the first time that find ">" before the line
			else{
				next;
			}
		}
	}
	elsif($_ eq ""){
		next;
	}
	else{
		#get the sequences and connect them
		$last_col = $_;
		$seq .= $last_col;
	}
}

#start sequence processing when get the last sequence
$len = length($seq);

for(my $kmer=$minLen;$kmer<=$maxLen;$kmer++){
	if($len <= $kmer){
		$hash{$kmer}{$seq}++;
	}
	#record long sequences after processing
	else{
		for(my $i=0;$i<=$len - $kmer;$i++){
			$seq_splited = substr($seq,$i,$kmer);
			if(exists $hash{$kmer}{$seq_splited}){
				$hash{$kmer}{$seq_splited}++;
			}
			else{
				$hash{$kmer}{$seq_splited} = 1;
			}
		}
	}
}

#output the split result
open SUM,">$outdir/$prefix.searchSpace.ss" or die "Can not open $outdir/$prefix.searchSpace.ss:$!\n";
foreach my $key1 (sort { $hash{$a} <=> $hash{$b} } keys %hash){
	open OUT,">$outdir/$prefix.${key1}mer.txt" or die "Can not open $outdir/$prefix.${key1}mer.txt:$!\n";
	print SUM "$outdir/$prefix.${key1}mer.txt\t$key1\n";
	foreach my $key2 (keys %{$hash{$key1}}){
		print OUT $key2."\n";
	}
	close OUT;
}
close SUM;
close OUT;
