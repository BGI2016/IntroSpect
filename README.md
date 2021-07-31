# IntroSpect
IntroSpect is a motif-guided immunopeptidome database building tool to improve the sensitivity of HLA binding peptide identification. It is a command-line tool written in Perl which requires GibbsCluster v2.0 preinstalled, in Darwin (Mac) or Linux platforms. The tool takes an input protein FASTA database and peptides identified by conventional search and outputs targeted database which could be used for refined high sensitivity identification.

# Download and install
Please download the file "IntroSpect-1.0.tar.gz" and unpackage.
```sh
tar -xzvf IntroSpect-1.0.tar.gz.
```

# Running
```sh
cd ./IntroSpect-1.0
perl ./IntroSpect.pl
```

# Run the example
```sh
cd ./IntroSpect-1.0/TEST
sh run.sh
sh ./analysis/0.shell/RUNALL.sh
```

# License
See included file LICENSE.

Please contact zhangle2@genomics.cn or libo@genomics.cn if any questions about IntroSpect.
