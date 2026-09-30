#!/bin/bash

#############################################################
# Shotgun Metagenomics Pipeline - Installation
#############################################################

set -e


echo "Creating Conda environments..."


#############################################################
# TAXONOMIC ENVIRONMENT
#############################################################

conda create -n MG-Shotgun \
-c bioconda \
-c conda-forge \
metaphlan \
"bowtie2>=2.5" \
samtools \
fastqc \
fastp \
-y



#############################################################
# FUNCTIONAL ENVIRONMENT
#############################################################

conda create -n HUMAnN-func \
-c bioconda \
-c conda-forge \
python=3.9 \
"humann=3.9" \
"metaphlan>=4.1,<4.2" \
"bowtie2>=2.5" \
diamond=2.0.15 \
-y



#############################################################
# CREATE DIRECTORIES
#############################################################

echo "Creating folders..."


export H=$HOME


mkdir -p \
$H/databases/{uniref,chocophlan,metaphlan,host_human,utility_mapping}



mkdir -p \
$H/PROJECT/{raw_fastq,metadata,scripts,logs}



mkdir -p \
$H/PROJECT/results/{01_qc,02_host_removed,03_metaphlan,04_humann3}




#############################################################
# DOWNLOAD HUMANN DATABASES
#############################################################

echo "Downloading HUMAnN databases..."


conda activate HUMAnN-func


humann_databases \
--download chocophlan full \
$H/databases/chocophlan


humann_databases \
--download uniref uniref90_diamond \
$H/databases/uniref


humann_databases \
--download utility_mapping full \
$H/databases/utility_mapping





#############################################################
# INSTALL METAPHLAN DATABASE
#############################################################

echo "Installing MetaPhlAn database..."


metaphlan \
--install \
--bowtie2db $H/databases/metaphlan





#############################################################
# CONFIGURE HUMANN
#############################################################

echo "Configuring HUMAnN..."


humann_config \
--update database_folders nucleotide \
$H/databases/chocophlan


humann_config \
--update database_folders protein \
$H/databases/uniref


humann_config \
--update database_folders utility_mapping \
$H/databases/utility_mapping


humann_config \
--update run_modes threads 12





#############################################################
# TEMP DIRECTORY
#############################################################

mkdir -p $H/humann_tmp


grep -qxF "export TMPDIR=$H/humann_tmp" ~/.bashrc || \
echo "export TMPDIR=$H/humann_tmp" >> ~/.bashrc





#############################################################
# CHECK INSTALLATION
#############################################################

echo "Checking installed tools..."


conda activate MG-Shotgun


which bowtie2

bowtie2 --version | head -1

metaphlan --version



conda activate HUMAnN-func


humann --version



echo "Installation completed successfully!"