#!/bin/bash
#
# Setup a Stenglein lab analysis server
#
# This is based on How I setup the cctsi-103 server
# goal: create a re-usable script for server setup
#
# This done on cctsi-103 server with Ubuntu 16.04
# 
# 5/17/2017
# Mark Stenglein

# TODO: convert this to make/snakemake format


# kludgy way to only execute part of the script
if [ "dont_do_this_part_already_done" = "XXX" ]
then

echo "bla bla bla" > /dev/null

# just keep moving this else down to keep adding to what will get done
else


# update packages
echo "Going to run Ubuntu updates. Press enter to continue."
read x
sudo apt-get update
sudo apt-get upgrade

# setup UFW firewall
# see: https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04
sudo ufw app list
echo "should see: Available applications: OpenSSH"

sudo ufw allow OpenSSH

echo "check UFW status"
sudo ufw status

echo "going to enable UFW firewall (press Y to continue)"
sudo ufw enable

echo "check UFW status: should be active w/ OpenSSH connections enabled"
sudo ufw status


# install HDF5 libs, for utils like h5dump
sudo apt-get update
sudo apt-get install -y libhdf5-serial-dev
sudo apt install -y hdf5-tools

# Now, install LAMP: Apache, MySQL, PHP (precursors for webmin)
# see: https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04

# install Apache
sudo apt-get update
sudo apt-get install -y apache2

echo "Checking Apache Config.  Should see 'Sytnax OK' as output"
sudo apache2ctl configtest

echo "going to enable web traffic through firewall"
# sudo ufw app list

sudo ufw allow in "Apache Full"

echo "if you navigate to this host's hostname in a browser you should see a default Apache page"


# MySQL
echo "setting up MySQL"
sudo apt-get install -y mysql-server

echo "securing MySQL"
echo "answer No to first 2 questions (VALIDATE PASSWORD PLUGIN and Change the password for root and Yes to the rest.  See:"
echo "https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04"
mysql_secure_installation


# PHP
echo "installing PHP"
sudo apt-get install -y php libapache2-mod-php php-mcrypt php-mysql

# echo "give PHP files priority over HTML"



# Webmin
echo "going to install Webmin"
echo "see: https://www.digitalocean.com/community/tutorials/how-to-install-webmin-on-ubuntu-16-04"
echo "  "
echo "going to edit /etc/apt/sources.list with vi.  Add the following line to the bottom of that file and save:"
echo "deb http://download.webmin.com/download/repository sarge contrib" 
echo "<enter> to continue: "
read x
sudo vi /etc/apt/sources.list

echo "adding Webmin PGP key"
echo "should see 'OK' after adding key"
wget http://www.webmin.com/jcameron-key.asc
sudo apt-key add jcameron-key.asc

# refresh w/ Webmin info
sudo apt-get update

# actually install Webmin
echo "installing webmin."
echo "you should see output at end like: Webmin install complete. You can now login to https://..."
sudo apt-get install -y webmin


# allow Webmin through firewall
sudo ufw allow 10000

echo "now you can navigate to this https://<this_hostname>:10000 to login to webmin"

# SSL certificate setup for webmin to avoid ugly warning 
# can't use Let's Encrypt to do SSL cert. because CSU servers behind a firewall that won't let let's encrypt connect to the server :<
# echo "follow instructions at: https://www.digitalocean.com/community/tutorials/how-to-install-webmin-on-ubuntu-16-04"
# echo "   to setup SSL certificate that won't give error"


# setup .bashrc of my user

bashrc=$(cat <<'END_BASHRC'

# use vi to do command line editing
set -o vi

# don't overwrite files
set -o noclobber

#--------
# aliases
#--------
# Prevent accidentally clobbering files.
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# ls aliases
alias ll='ls -l --color'
alias ls='ls -hF --color'         # colors
alias lk='ls -lSrh'               # sort by size, biggest last
alias lt='ls -ltr --color'        # sort by date, most recent last

alias more='less'
export PAGER=less

export PERL5LIB=$PERL5LIB:~/bin

PATH="${PATH}:/home/apps/bin"

END_BASHRC
)

echo "Adding the following lines to .bashrc:"
echo "$bashrc" 
echo "$bashrc" >> ~/.bashrc

# setup ~/bin
# do this manually  before running this script.
## cd
## mkdir bin
## cd bin
## clone scripts from github
## git clone https://github.com/stenglein-lab/stenglein_lab_scripts.git .

# to update local repo from remote: run: git fetch; git pull

# Setup /home/apps folder
cd /home
sudo mkdir apps
cd apps
sudo chown -R `whoami` .
mkdir bin

# download unzip
sudo apt-get install -y zip unzip


# install R
echo "going to install R"
echo "enter to continue"
read x
sudo apt-get install -y r-base

# install Java
sudo apt-get update
sudo apt-get install -y default-jdk
echo "running java -version: should work"
echo "enter to continue"
read x
echo "java -version"
java -version
echo "enter to continue"
read x

# install pip (python package manager)
sudo apt-get install -y python-pip


# Setup /home/databases folder
cd /home
sudo mkdir databases
sudo chown mdstengl databases
cd databases



# install various apps

# download bowtie2
echo installing bowtie2
cd /home/apps
wget https://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.3.2/bowtie2-2.3.2-linux-x86_64.zip
unzip bowtie2-2.3.2-linux-x86_64.zip
cd bowtie2-2.3.2
cp bowtie2* /home/apps/bin
cd /home/apps

# install cutadapt
echo "installing cutadapt.  Note, won't install to /home/apps/bin"
echo enter to continue
read x
sudo pip install --upgrade cutadapt

# install FastQC
echo "going to install FastQC.  Note: may be a newer version: check website: https://www.bioinformatics.babraham.ac.uk/projects/fastqc"
echo "enter to continue"
read x
cd /home/apps
curl -O https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip
unzip fastqc_v0.11.5.zip
cd FastQC
chmod +x fastqc
cd /home/apps/bin
# create a symbolic link to the fastqc executable 
ln -s ../FastQC/fastqc fastqc

# install galaxy
echo "going to install galaxy"
gal_ver="release_17.01"
echo "NOTE: going to install version: $gal_Ver"
echo "could update in future by running git checkout & git pull.   See: https://galaxyproject.org/admin/get-galaxy/ "
echo enter to continue
cd /home/apps
git clone -b $gal_ver https://github.com/galaxyproject/galaxy.git
cd galaxy
# allow galaxy port 8080 through firewall
sudo ufw allow 8080
cd config
cp galaxy.ini.sample galaxy.ini
echo "edit galaxy.ini and add the following line: "
echo "host = 0.0.0.0"
echo enter to edit
read x
vi galaxy.ini
cd /home/apps

# to run galaxy:
# echo: to run galaxy: sh run.sh
# sh run.sh

# install canu assembler
echo install canu assembler
wget https://github.com/marbl/canu/releases/download/v1.5/canu-1.5.Linux-amd64.tar.xz
tar xvf canu-1.5.Linux-amd64.tar.xz
# TODO: install canu executables somehow?
cd /home/apps

# install gnuplot
echo install gnuplot
sudo apt-get update
sudo apt-get install -y gnuplot

# install graphmap
echo install graphmap
cd /home/apps
echo install graphmap
git clone https://github.com/isovic/graphmap.git
cd graphmap
make modules
make
cp bin/Linux-x64/graphmap /home/apps/bin
cd /home/apps

# install htop
echo install htop
sudo apt-get update
sudo apt-get install -y htop

# install biopython and numpy
echo install biopython and numpy
echo install numpy
cd /home/apps
curl -O https://pypi.python.org/packages/c0/3a/40967d9f5675fbb097ffec170f59c2ba19fc96373e73ad47c2cae9a30aed/numpy-1.13.1.zip
unzip numpy-1.13.1.zip
cd numpy-1.13.1
python setup.py build
sudo python setup.py install
echo install biopython
cd /home/apps
git clone git://github.com/biopython/biopython.git
cd biopython
sudo python setup.py install
cd /home/apps

# install iotop 
sudo apt-get install -y iotop -y

# install nanopolish
echo install nanopolish
cd /home/apps
git clone --recursive https://github.com/jts/nanopolish.git
cd nanopolish/
make
cp nanopolish nanopolish_test /home/apps/bin
cd scripts
cp * /home/apps/bin
cd /home/apps


# install cmake (SPAdes,etc dependency)
echo "install cmake (SPAdes,etc dependency)"
sudo apt-get update
sudo apt install -y cmake

# install SPADES
echo install SPADES
cd /home/apps
wget http://cab.spbu.ru/files/release3.10.1/SPAdes-3.10.1.tar.gz
tar -xzf SPAdes-3.10.1.tar.gz
cd SPAdes-3.10.1
PREFIX=/home/apps ./spades_compile.sh
cd /home/apps

# install bwa
echo install bwa
cd /home/apps
git clone https://github.com/lh3/bwa.git
cd bwa; make
cp bwa /home/apps/bin
cd /home/apps

# install parallel
echo install parallel
sudo apt-get install -y parallel

# install samtools
echo install samtools
cd /home/apps
wget https://github.com/samtools/samtools/releases/download/1.5/samtools-1.5.tar.bz2
bunzip2 samtools-1.5.tar.bz2
tar xvf samtools-1.5.tar
cd samtools-1.5/
./configure --prefix=/home/apps
make
make install
cd /home/apps

# install BBTools
echo install BBTools
cd /home/apps
wget https://downloads.sourceforge.net/project/bbmap/BBMap_37.36.tar.gz
tar xvzf BBMap_37.36.tar.gz
# TODO: figure out how to install?

# install cd-hit
echo install cd-hit
cd /home/apps
# wget https://github.com/weizhongli/cdhit/releases/download/V4.6.8/cd-hit-v4.6.8-2017-0621-source.tar.gz
git clone https://github.com/weizhongli/cdhit.git
cd cdhit
make
cp cd-hit* /home/apps/bin
cd /home/apps

# install gmap
echo install gmap - NOTE: gmap is frequently updated.  Should probably update this URL
echo enter to continue
read x
wget http://research-pub.gene.com/gmap/src/gmap-gsnap-2017-06-20.tar.gz
tar xvzf gmap-gsnap-2017-06-20.tar.gz
cd gmap-2017-06-20
./configure --prefix=/home/apps
make
make check
make install

# install HiSat
echo install HiSat
cd /home/apps
wget ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/downloads/hisat2-2.1.0-Linux_x86_64.zip
unzip hisat2-2.1.0-Linux_x86_64.zip
cd hisat2-2.1.0
cp hisat2* /home/apps/bin
cd /home/apps

# install BLAST+
echo install BLAST+
cd /home/apps
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.6.0+-x64-linux.tar.gz
tar xvzf ncbi-blast-2.6.0+-x64-linux.tar.gz
cd ncbi-blast-2.6.0+/bin
cp * /home/apps/bin
cd /home/apps

# install mafft
echo install mafft
cd /home/apps
wget http://mafft.cbrc.jp/alignment/software/mafft-7.310-with-extensions-src.tgz
tar xvzf mafft-7.310-with-extensions-src.tgz
cd mafft-7.310-with-extensions/core
echo it is necessary to edit the Makefile to install to non-default location.
echo see: http://mafft.cbrc.jp/alignment/software/installation_without_root.html
echo going to vi Makefile
echo enter to continue
read x
# TODO: could change Makefile w/ sed...
vi Makefile
make clean
make
make install
cd /home/apps


# install sratoolkit
echo install sratoolkit
cd /home/apps
wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar xvzf sratoolkit.current-ubuntu64.tar.gz
cd sratoolkit.2.8.2-1-ubuntu64
cp bin/* /home/apps/bin
cp -R bin/ncbi /home/apps/bin
cd /home/apps

# Install BOOST
sudo apt-get install -y libboost-all-dev


# install RAPSearch
# TODO: Couldn't get rapsearch to work... --> some obscure BOOST issue.  Use diamond instead?
### echo install RAPSearch
### cd /home/apps
### wget https://downloads.sourceforge.net/project/rapsearch2/RAPSearch2.24_64bits.tar.gz
### tar xvzf RAPSearch2.24_64bits.tar.gz
### cd RAPSearch2.24_64bits/
### ./install
### cp bin/* /home/apps/bin
### cd /home/apps

# install diamond 
echo install diamond 
cd /home/apps
wget http://github.com/bbuchfink/diamond/releases/download/v0.9.9/diamond-linux64.tar.gz
tar xzf diamond-linux64.tar.gz
mv diamond bin 

### # install NFS client
### sudo apt-get update
### sudo apt-get install -y nfs-common


# install centrifuge
echo install centrifuge
cd /home/apps
git clone https://github.com/infphilo/centrifuge
cd centrifuge
make
make install prefix=/home/apps
cd /home/apps

# install BEAST
echo install BEAST
cd /home/apps
wget https://github.com/CompEvol/beast2/releases/download/v2.4.7/BEAST.v2.4.7.Linux.tgz
tar xvf BEAST.v2.4.7.Linux.tgz
# TODO: install BEAST to /home/apps possible?

## # install Vienna RNA package - requirement of centroidfold
## echo install Vienna RNA package - requirement of centroidfold
## cd /home/apps
## wget https://www.tbi.univie.ac.at/RNA/download/sourcecode/2_3_x/ViennaRNA-2.3.5.tar.gz
## tar xvf ViennaRNA-2.3.5.tar.gz
## cd ViennaRNA-2.3.5
## ./configure --prefix=/home/apps
## make
## make install
## cd /home/apps
## # note: got an error during make and make install.  Worked?
## # Could use pre-built binaries...

# install centroid fold
echo install centroid fold
cd /home/apps
wget https://github.com/satoken/centroid-rna-package/releases/download/v0.0.15/centroid-rna-package-0.0.15-linux-x86_64.zip
unzip centroid-rna-package-0.0.15-linux-x86_64.zip 
cd centroid-rna-package-0.0.15-linux-x86_64/
cp centroid_* /home/apps/bin
cd /home/apps

# install stringtie
echo install stringtie
cd /home/apps
wget http://ccb.jhu.edu/software/stringtie/dl/stringtie-1.3.3b.Linux_x86_64.tar.gz
tar xvf stringtie-1.3.3b.Linux_x86_64.tar.gz
cp stringtie-1.3.3b.Linux_x86_64/stringtie /home/apps/bin
cd /home/apps

# install jmodeltest 2
echo install jmodeltest 2
cd /home/apps
wget https://github.com/ddarriba/jmodeltest2/files/157117/jmodeltest-2.1.10.tar.gz
tar xvf jmodeltest-2.1.10.tar.gz
# TODO: possible to install to /home/apps/bin?  

## # install khmer using pip
## echo install khmer using pip
## pip install --upgrade pip
## pip install --install-option="--prefix=/home/apps" khmer
## # TODO: did this even work?

# install freebayes
echo install freebayes
cd /home/apps
git clone --recursive git://github.com/ekg/freebayes.git
cd freebayes
make
cp bin/freebayes bin/bamleftalign /home/apps/bin
cd /home/apps

# install lofreq
echo install lofreq
cd /home/apps
wget https://downloads.sourceforge.net/project/lofreq/lofreq_star-2.1.2_linux-x86-64.tgz
tar xvf lofreq_star-2.1.2_linux-x86-64.tgz
cp lofreq_star-2.1.2/bin/* /home/apps/bin
cd /home/apps

# install BEAGLE - used by MrBayes, BEAST, PhyML etc
cd /home/apps
git clone --depth=1 https://github.com/beagle-dev/beagle-lib.git
cd beagle-lib
./autogen.sh
./configure --prefix=/home/apps
make install

# install MrBayes
echo install MrBayes
cd /home/apps
wget https://downloads.sourceforge.net/project/mrbayes/mrbayes/3.2.6/mrbayes-3.2.6.tar.gz
tar xvf mrbayes-3.2.6.tar.gz
cd mrbayes-3.2.6/src
autoconf
./configure --enable-mpi=yes --prefix=/home/apps --with-beagle=/home/apps/
make
make install
cd /home/apps

# install muscle
echo install muscle
cd /home/apps
wget http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
tar xvf muscle3.8.31_i86linux64.tar.gz
mv muscle3.8.31_i86linux64 /home/apps/bin

# install PhyML
echo install PhyML
echo "note: the developers of PhyML would like your name and email.  Please go to: http://www.atgc-montpellier.fr/phyml/binaries.php"
cd /home/apps
wget http://www.atgc-montpellier.fr/download/binaries/phyml/PhyML-3.1.zip
unzip PhyML-3.1.zip
cp PhyML-3.1/PhyML-3.1_linux64 /home/apps/bin
cd /home/apps

# install quast
echo install quast
cd /home/apps
wget https://downloads.sourceforge.net/project/quast/quast-4.5.tar.gz
tar -xzf quast-4.5.tar.gz
cd quast-4.5
./install_full.sh
# TODO: install to /home/apps/bin possible?

# install STAR aligner
echo install STAR aligner
cd /home/apps
git clone https://github.com/alexdobin/STAR.git
cd STAR/source
make STAR
cp STAR /home/apps/bin

# install trimal
echo install trimal
cd /home/apps
git clone https://github.com/scapella/trimal.git
cd trimal/source
make
cp readal trimal statal /home/apps/bin
cd /home/apps/bin


# khmer
# htslib

# TODO: Setup taxonomy db
# mysql, populate database w/ taxonomy info...
# download NCBI dbs, make indexes
# setup cron job to update taxonomy db

# TODO: make this a snakemake or make

# TODO: setup sequence databases
# rsync from 101?
# setup cronjob to update nr/nt

# SysAdmin TODO:
# MegaCli (RAID analysis)
# setup RAID monitoring
# setup rsync backup (???)
# i.e. setup cron jobs

fi