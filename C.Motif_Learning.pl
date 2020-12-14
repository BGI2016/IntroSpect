#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

my $outdir;
my $file;
my %hash;
my $MinNum;
my $prefix;
my $current_path=$ENV{"PWD"};
my $usage = "\n\n$0 [options] \n

Usage: perl $0 -file infile -outdir outdir -prefix prefix

Options:

	-file				infile
	-outdir				output dir
	-MinNum				training set min number of each length and each allele [default:80]
	-prefix				output file prefix
	-help				Show this message

";

GetOptions(
	'file=s'				=>\$file,
	'outdir=s'				=>\$outdir,
	'MinNum=i'				=>\$MinNum,
	'prefix=s'				=>\$prefix,
	help					=> sub { pod2usage($usage); },
) or die($usage);

unless($file){
    die "Provide a file to perform motif learning, -file <infile> -outdir <outdir> -MinNum <MinNum>" , $usage;
}
$file="$current_path/$file" unless($file=~/^\//);

unless($outdir){
    die "Provide a outdir to perform motif learning, -file <infile> -outdir <outdir> -MinNum <MinNum>" , $usage;
}
$outdir="$current_path/$outdir" unless($outdir=~/^\//);

#default parameters
$MinNum=80 unless(defined $MinNum);

open FH,"<$file" or die "Can not open $file:$!\n";
open PSSMFILE,">$outdir/$prefix.pssm_file.list" or die "Can not open $outdir/$prefix.pssm_file.list:$!\n";

my @lib = ('A', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'Y');
my $IC50 = 0;
# Define background frequency in uniprot database
my %bg;
$bg{'A'} = 0.0826622168195282;
$bg{'C'} = 0.0136850332007961;
$bg{'D'} = 0.0545883107520953;
$bg{'E'} = 0.0675987909234391;
$bg{'F'} = 0.0386658831073075;
$bg{'G'} = 0.0708488499195514;
$bg{'H'} = 0.0227226416223757;
$bg{'I'} = 0.0597571006180889;
$bg{'K'} = 0.0585272272907145;
$bg{'L'} = 0.096681402591599;
$bg{'M'} = 0.0242260080622711;
$bg{'N'} = 0.0406364484957737;
$bg{'P'} = 0.0469865264985876;
$bg{'Q'} = 0.0393742846376247;
$bg{'R'} = 0.0553599274523758;
$bg{'S'} = 0.0654447212017059;
$bg{'T'} = 0.0533960101143632;
$bg{'V'} = 0.0687266172099021;
$bg{'W'} = 0.0108407347094559;
$bg{'Y'} = 0.0292109734641572;

#Set Dirchlet mix distrubution to avoid overfit
my ($dirchlet, $dirchlet_all, $dirchlet_ic50) = (1, 20, 1000);

my $species="HUMAN";
my %db;
while(<FH>)
{
	chomp;
	my @tmp = split /\s+/;
	next if($tmp[1] ne $species);
	push @{$db{$tmp[3]}{$tmp[6]}}, $tmp[5];
}
close FH;

for my $allele (keys %db)
{
	for my $len (keys %{$db{$allele}})
	{
		open(PSSM, ">$outdir/$allele\_$len.pssm") || die $!;
		my @s = @{$db{$allele}{$len}};
		next if(($#s + 1) < $MinNum);

		open(OUT, ">$outdir/train.seq") || die $!;
		print OUT ">$allele $len\n";
		foreach my $x (@s)
		{
			print OUT "$x\n";
		}
		close OUT;
		# Read peptides from input file
		my @seq;
		my @ic50;
		local $/ = "\n>";
		open(IN, "$outdir/train.seq") || die $!;
		while(<IN>)
		{
			chomp;
			s/^>//;
			my @tmp = split /\n/, $_;
			# Get MHC type and peptides lenngth.
			my ($allel, $len) = split /\s+/, $tmp[0];
			my $num = $#tmp;
			for my $i (1..$num)
			{
				($seq[$i-1], $ic50[$i-1]) = split /\s+/, $tmp[$i];
				$seq[$i-1] = uc($seq[$i-1]);
				die "The $i peptides has a wrong length!\n" if(length($seq[$i-1]) != $len);
			}
			# Build PSSM
			my %pssm;
			for my $j (0..$len-1)
			{
				foreach my $char (@lib)
				{
					$pssm{$char}[$j] = 0;
				}
				my $all = 0;
				for my $i (0..$num-1)
				{
					my $char = substr($seq[$i], $j, 1);
					my $frq = 1;
					$frq = $frq / $ic50[$i] if($IC50 == 1);
					$all += $frq;
					$pssm{$char}[$j] += $frq;
				}

				foreach my $char (@lib)
				{
					my $tmp = log(($pssm{$char}[$j]+$dirchlet)/($all+$dirchlet_all)/$bg{$char});
					$tmp = log(($pssm{$char}[$j]+$dirchlet/$dirchlet_ic50)/($all+$dirchlet_all/$dirchlet_ic50)/$bg{$char}) if($IC50 == 1);
					$pssm{$char}[$j] = $tmp;
				}
			}
			# OUtput 
			print PSSM ">$tmp[0]\n";
			foreach my $char (@lib)
			{
				for my $j(0..$len-1)
				{
					print PSSM "$pssm{$char}[$j]\t";
				}
				print PSSM "\n";
			}
		}
		close IN;
		local $/ = "\n";
		`rm $outdir/train.seq`;
		print PSSMFILE "$outdir/$allele\_$len.pssm\t$allele\t$len\n";
		close PSSM;
	}
}



close PSSMFILE;
close OUT;

