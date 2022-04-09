# IntroSpect
IntroSpect is a motif-guided immunopeptidome database building tool to improve the sensitivity of HLA binding peptide identification. It is a command-line tool written in Perl which requires GibbsCluster v2.0 preinstalled, in Darwin (Mac) or Linux platforms. The tool takes an input protein FASTA database and peptides identified by conventional search and outputs targeted database which could be used for refined high sensitivity identification.

# Download and install
Please download the file [IntroSpect_v1.0.0.zip](https://github.com/BGI2016/IntroSpect/releases/tag/Latest) and unpackage .
-  You will need to install [GibbsCluster-2.0](https://services.healthtech.dtu.dk/service.php?GibbsCluster-2.0) before running IntroSpect.

# Before Running
Here, we assume that you have completed a database search of the immunopeptidome from a Hela cell line based on one common search tools (e.g. MaxQuant). The name of the protein library you use is __'uniprot.human.fasta'__, and the list of peptides you get is __'hela.txt'__ (This file has a single column of peptide sequences that have been removed the modification information, and no headers are required).

# Running
1. Convert the database file to search space file
-  The __'-file'__ should be set as the fasta file which you originally used for database search (e.g. uniprot.human.fasta). 
-  The __'-minLen'__ and "-maxLen" shoule be set according to the pMHC feature (e.g. -minLen 8 -maxLen 15). 
-  The __'-prefix'__ should be set according to your requirements (e.g. Human.IntroSpect)
```sh
perl ./DB2SS.pl -file uniprot.human.fasta -minLen 8 -maxLen 15 -prefix Human.IntroSpect -outdir ./SearchSpace
```
-  The results include serveral TXT files (Human.IntroSpect_*mer_filter.txt) and an SS file (Human.IntroSpect.ss). The TXT files contains the peptides splited from your protein database, and the SS file contains the path of these TXT files.

2. Based on your previous database search results, filter the search space files to get a targeted database.
-  The __'-ss'__ should be set as the SS file which you generated in the previous step.
-  The __'-pep'__ should be set as the peptide list file you identified from conventional database search (e.g. hela.txt).
-  The __'-GC'__ should be set as the path of pre-install GibbsCluster.
-  You can view other advanced parameters by using __'-help'__.
```sh
perl ./IntroSpect.pl -ss Human.IntroSpect.ss -pep hela.txt -prefix Hela -GC YourGibbsClusterPath/gibbscluster -outdir ./Hela
cd ./Hela/0.shell/
sh ./RUNALL.sh
```
-  The results include GibbsCluster and PSSM intermediate files, as well as the final target database (./3.result/Hela.IntroSpect.fasta). You can now re-perform your database search using this targeted database.


# License
See included file LICENSE.

Please contact zhangle2@genomics.cn or libo@genomics.cn if any questions about IntroSpect.
