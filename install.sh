#!/bin/bash

#############################################################
# Shotgun Metagenomics Pipeline - Installation
#############################################################

set -e


#############################################################
# INITIALIZE CONDA
#############################################################

source ~/mambaforge/etc/profile.d/conda.sh



#############################################################
# SETTINGS
#############################################################

export H=$HOME

PROJECT_NAME=${1:-MG_Project}

PROJECT_DIR=${H}/${PROJECT_NAME}



#############################################################
# CREATE CONDA ENVIRONMENTS
#############################################################

echo "Checking Conda environments..."



#############################################################
# TAXONOMIC ENVIRONMENT
#############################################################

if conda env list | grep -q "^MG-Shotgun"

then

    echo "MG-Shotgun environment already exists"

else

    echo "Creating MG-Shotgun environment..."


    conda create \
    -n MG-Shotgun \
    -c conda-forge \
    -c bioconda \
    metaphlan \
    "bowtie2>=2.5" \
    samtools \
    fastqc \
    fastp \
    -y

fi




#############################################################
# FUNCTIONAL ENVIRONMENT
#############################################################

if conda env list | grep -q "^HUMAnN-func"

then

    echo "HUMAnN-func environment already exists"


else

    echo "Creating HUMAnN-func environment..."


    conda create \
    -n HUMAnN-func \
    python=3.9 \
    -y


    conda activate HUMAnN-func


    echo "Installing HUMAnN..."

    pip install humann==3.9



    echo "Installing HUMAnN dependencies..."


    conda install \
    -c conda-forge \
    -c bioconda \
    "metaphlan>=4.1,<4.2" \
    "bowtie2>=2.5" \
    diamond=2.0.15 \
    -y


    conda deactivate


fi




#############################################################
# VERIFY HUMANN INSTALLATION
#############################################################

echo "Checking HUMAnN installation..."


conda activate HUMAnN-func


if humann --version >/dev/null 2>&1

then

    echo "HUMAnN installation verified"

else

    echo "ERROR: HUMAnN is not working correctly"
    exit 1

fi


conda deactivate





#############################################################
# CREATE DIRECTORIES
#############################################################

echo "Creating database folders..."


mkdir -p \
${H}/databases/{uniref,chocophlan,metaphlan,host_human,utility_mapping}




echo "Creating project folders..."


mkdir -p \
${PROJECT_DIR}/{raw_fastq,metadata,scripts,logs}


mkdir -p \
${PROJECT_DIR}/results/{01_qc,02_host_removed,03_metaphlan,04_humann3}



echo "Project created:"
echo ${PROJECT_DIR}




#############################################################
# DOWNLOAD HUMANN DATABASES
#############################################################

echo "Checking HUMAnN databases..."


conda activate HUMAnN-func



############################
# ChocoPhlAn
############################

if [ -z "$(ls ${H}/databases/chocophlan 2>/dev/null)" ]

then

echo "Downloading ChocoPhlAn..."


humann_databases \
--download chocophlan full \
${H}/databases/chocophlan


else

echo "ChocoPhlAn already present"

fi



############################
# UniRef90
############################

if [ -z "$(ls ${H}/databases/uniref 2>/dev/null)" ]

then

echo "Downloading UniRef90..."


humann_databases \
--download uniref uniref90_diamond \
${H}/databases/uniref


else

echo "UniRef90 already present"

fi



############################
# Utility mapping
############################

if [ -z "$(ls ${H}/databases/utility_mapping 2>/dev/null)" ]

then

echo "Downloading utility mapping..."


humann_databases \
--download utility_mapping full \
${H}/databases/utility_mapping


else

echo "Utility mapping already present"

fi


conda deactivate





#############################################################
# INSTALL METAPHLAN DATABASE
#############################################################

echo "Checking MetaPhlAn database..."


conda activate MG-Shotgun



if [ -z "$(ls ${H}/databases/metaphlan 2>/dev/null)" ]

then

echo "Installing MetaPhlAn database..."


metaphlan \
--install \
--db_dir ${H}/databases/metaphlan


else

echo "MetaPhlAn database already present"

fi


conda deactivate





#############################################################
# CONFIGURE HUMANN
#############################################################

echo "Configuring HUMAnN..."


conda activate HUMAnN-func



humann_config \
--update database_folders nucleotide \
${H}/databases/chocophlan



humann_config \
--update database_folders protein \
${H}/databases/uniref



humann_config \
--update database_folders utility_mapping \
${H}/databases/utility_mapping



humann_config \
--update run_modes threads 12



conda deactivate





#############################################################
# TEMP DIRECTORY
#############################################################

mkdir -p ${H}/humann_tmp


grep -qxF "export TMPDIR=${H}/humann_tmp" ~/.bashrc || \
echo "export TMPDIR=${H}/humann_tmp" >> ~/.bashrc





#############################################################
# FINAL CHECK
#############################################################

echo "Checking installed tools..."



conda activate MG-Shotgun


echo "Bowtie2:"
which bowtie2

bowtie2 --version | head -1


echo "MetaPhlAn:"
metaphlan --version



conda deactivate



conda activate HUMAnN-func


echo "HUMAnN:"
humann --version


conda deactivate




echo ""
echo "======================================"
echo "Installation completed successfully!"
echo "Project directory:"
echo ${PROJECT_DIR}
echo "======================================"