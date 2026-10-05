#!/bin/bash

#############################################################
# Shotgun Metagenomics Pipeline - Installation / Setup
#############################################################
#
# SAFETY RULES
#
# 1. The Turing "base" environment is NEVER modified.
# 2. Conda is used only for the two pipeline environments.
# 3. Existing MG-Shotgun and HUMAnN-func environments are
#    NEVER modified.
# 4. No conda init is performed.
# 5. No conda update is performed.
# 6. ~/.bashrc is NEVER modified.
# 7. Reference databases are reused if already present.
#
#############################################################

set -euo pipefail


#############################################################
# PROTECT TURING BASE ENVIRONMENT
#############################################################

if [ "${CONDA_DEFAULT_ENV:-}" = "base" ]
then

    echo ""
    echo "ERROR: The Turing base environment is active."
    echo ""
    echo "This installer refuses to run from base."
    echo ""
    echo "Run:"
    echo ""
    echo "    conda deactivate"
    echo ""
    echo "until the '(base)' prefix disappears."
    echo ""

    exit 1

fi


#############################################################
# SETTINGS
#############################################################

H="${HOME}"

PROJECT_NAME="${1:-MG_Project}"

PROJECT_DIR="${H}/${PROJECT_NAME}"


#############################################################
# CONDA
#############################################################

# Direct path to Conda.
#
# No conda activation is required.
# No conda init is performed.

CONDA="${H}/mambaforge/bin/conda"


if [ ! -x "${CONDA}" ]
then

    echo ""
    echo "ERROR: Conda executable not found:"
    echo "${CONDA}"
    echo ""

    exit 1

fi


#############################################################
# ENVIRONMENT PATHS
#############################################################

MG_ENV="${H}/mambaforge/envs/MG-Shotgun"

HUMANN_ENV="${H}/mambaforge/envs/HUMAnN-func"


#############################################################
# DATABASE PATHS
#############################################################

DB_DIR="${H}/databases"


#############################################################
# HUMANN DATABASES
#############################################################

CHOCOPHLAN_DB="${DB_DIR}/chocophlan"

UNIREF_DB="${DB_DIR}/uniref"

UTILITY_DB="${DB_DIR}/utility_mapping"


#############################################################
# METAPHLAN DATABASE - MG-SHOTGUN
#############################################################

METAPHLAN_DB="${DB_DIR}/metaphlan"


#############################################################
# METAPHLAN DATABASE - HUMANN
#############################################################

HUMANN_METAPHLAN_DB="${DB_DIR}/metaphlan_humann"

HUMANN_METAPHLAN_INDEX="mpa_vJun23_CHOCOPhlAnSGB_202403"


#############################################################
# HUMAN GENOME DATABASE
#############################################################

HUMAN_DB_DIR="${DB_DIR}/host_human"


#############################################################
# EXPECTED SOFTWARE VERSIONS
#############################################################

MG_METAPHLAN_VERSION="4.2.5"

HUMANN_METAPHLAN_VERSION="4.1.2"

HUMANN_VERSION="3.9"


#############################################################
# ENVIRONMENT CREATION
#############################################################

echo ""
echo "======================================"
echo "Checking pipeline environments"
echo "======================================"


#############################################################
# MG-SHOTGUN
#############################################################

if [ -d "${MG_ENV}" ]
then

    echo ""
    echo "MG-Shotgun environment already exists:"
    echo "${MG_ENV}"
    echo ""
    echo "Existing environment will NOT be modified."

else

    echo ""
    echo "MG-Shotgun environment not found."
    echo "Creating MG-Shotgun..."
    echo ""

    "${CONDA}" create \
        -n MG-Shotgun \
        -c conda-forge \
        -c bioconda \
        "metaphlan==${MG_METAPHLAN_VERSION}" \
        "bowtie2>=2.5" \
        samtools \
        fastqc \
        fastp \
        -y

fi


#############################################################
# HUMANN-FUNC
#############################################################

if [ -d "${HUMANN_ENV}" ]
then

    echo ""
    echo "HUMAnN-func environment already exists:"
    echo "${HUMANN_ENV}"
    echo ""
    echo "Existing environment will NOT be modified."

else

    echo ""
    echo "HUMAnN-func environment not found."
    echo "Creating HUMAnN-func..."
    echo ""

    "${CONDA}" create \
        -n HUMAnN-func \
        python=3.9 \
        pip \
        -y


    echo ""
    echo "Installing HUMAnN dependencies..."
    echo ""

    "${CONDA}" install \
        -n HUMAnN-func \
        -c conda-forge \
        -c bioconda \
        "metaphlan==${HUMANN_METAPHLAN_VERSION}" \
        "bowtie2>=2.5" \
        diamond=2.0.15 \
        -y


    echo ""
    echo "Installing HUMAnN ${HUMANN_VERSION}..."
    echo ""

    "${HUMANN_ENV}/bin/python" \
        -m pip install \
        "humann==${HUMANN_VERSION}"

fi


#############################################################
# SOFTWARE PATHS
#############################################################

METAPHLAN="${MG_ENV}/bin/metaphlan"

BOWTIE2="${MG_ENV}/bin/bowtie2"

BOWTIE2_BUILD="${MG_ENV}/bin/bowtie2-build"

FASTQC="${MG_ENV}/bin/fastqc"

FASTP="${MG_ENV}/bin/fastp"

SAMTOOLS="${MG_ENV}/bin/samtools"

MERGE_METAPHLAN="${MG_ENV}/bin/merge_metaphlan_tables.py"


HUMANN="${HUMANN_ENV}/bin/humann"

HUMANN_DATABASES="${HUMANN_ENV}/bin/humann_databases"

HUMANN_CONFIG="${HUMANN_ENV}/bin/humann_config"

HUMANN_METAPHLAN="${HUMANN_ENV}/bin/metaphlan"

HUMANN_BOWTIE2="${HUMANN_ENV}/bin/bowtie2"

HUMANN_BOWTIE2_BUILD="${HUMANN_ENV}/bin/bowtie2-build"

HUMANN_BOWTIE2_INSPECT="${HUMANN_ENV}/bin/bowtie2-inspect"

DIAMOND="${HUMANN_ENV}/bin/diamond"


#############################################################
# CHECK SOFTWARE
#############################################################

echo ""
echo "======================================"
echo "Checking installed software"
echo "======================================"


for TOOL in \
    "${METAPHLAN}" \
    "${BOWTIE2}" \
    "${BOWTIE2_BUILD}" \
    "${FASTQC}" \
    "${FASTP}" \
    "${SAMTOOLS}" \
    "${MERGE_METAPHLAN}" \
    "${HUMANN}" \
    "${HUMANN_DATABASES}" \
    "${HUMANN_CONFIG}" \
    "${HUMANN_METAPHLAN}" \
    "${HUMANN_BOWTIE2}" \
    "${HUMANN_BOWTIE2_BUILD}" \
    "${HUMANN_BOWTIE2_INSPECT}" \
    "${DIAMOND}"
do

    if [ ! -x "${TOOL}" ]
    then

        echo ""
        echo "ERROR: Required executable not found:"
        echo "${TOOL}"
        echo ""

        exit 1

    fi

done


#############################################################
# VERSION CHECKS
#############################################################

echo ""
echo "MG-Shotgun MetaPhlAn:"
"${METAPHLAN}" --version


echo ""
echo "HUMAnN:"
"${HUMANN}" --version


echo ""
echo "HUMAnN-func MetaPhlAn:"
"${HUMANN_METAPHLAN}" --version


echo ""
echo "MG-Shotgun Bowtie2:"
"${BOWTIE2}" --version | head -1


echo ""
echo "HUMAnN-func Bowtie2:"
"${HUMANN_BOWTIE2}" --version | head -1


#############################################################
# VERIFY HUMANN METAPHLAN VERSION
#############################################################

HUMANN_MPA_VERSION="$(
    "${HUMANN_METAPHLAN}" --version |
    awk '{print $3}'
)"


if [ "${HUMANN_MPA_VERSION}" != "${HUMANN_METAPHLAN_VERSION}" ]
then

    echo ""
    echo "ERROR: Existing HUMAnN-func contains MetaPhlAn:"
    echo "${HUMANN_MPA_VERSION}"
    echo ""
    echo "Expected:"
    echo "${HUMANN_METAPHLAN_VERSION}"
    echo ""
    echo "The installer will NOT modify the existing environment."
    echo ""

    exit 1

fi


#############################################################
# CREATE DATABASE DIRECTORIES
#############################################################

echo ""
echo "======================================"
echo "Creating/checking database directories"
echo "======================================"


mkdir -p \
    "${CHOCOPHLAN_DB}" \
    "${UNIREF_DB}" \
    "${UTILITY_DB}" \
    "${METAPHLAN_DB}" \
    "${HUMANN_METAPHLAN_DB}" \
    "${HUMAN_DB_DIR}"


#############################################################
# CREATE PROJECT DIRECTORIES
#############################################################

echo ""
echo "======================================"
echo "Creating project directories"
echo "======================================"


mkdir -p \
    "${PROJECT_DIR}/raw_fastq" \
    "${PROJECT_DIR}/metadata" \
    "${PROJECT_DIR}/scripts" \
    "${PROJECT_DIR}/logs" \
    "${PROJECT_DIR}/results/01_qc" \
    "${PROJECT_DIR}/results/02_host_removed" \
    "${PROJECT_DIR}/results/03_metaphlan" \
    "${PROJECT_DIR}/results/04_humann3"


echo ""
echo "Project created:"
echo "${PROJECT_DIR}"


#############################################################
# HUMANN DATABASES
#############################################################

echo ""
echo "======================================"
echo "Checking HUMAnN databases"
echo "======================================"


#############################################################
# CHOCOPHLAN
#############################################################

if find "${CHOCOPHLAN_DB}" \
    -type f \
    -print -quit 2>/dev/null | grep -q .
then

    echo ""
    echo "ChocoPhlAn database found."

else

    echo ""
    echo "ChocoPhlAn database not found."
    echo "Downloading ChocoPhlAn..."
    echo ""

    "${HUMANN_DATABASES}" \
        --download chocophlan full \
        "${CHOCOPHLAN_DB}"

fi


#############################################################
# UNIREF90
#############################################################

if find "${UNIREF_DB}" \
    -type f \
    -print -quit 2>/dev/null | grep -q .
then

    echo ""
    echo "UniRef database found."

else

    echo ""
    echo "UniRef90 database not found."
    echo "Downloading UniRef90..."
    echo ""

    "${HUMANN_DATABASES}" \
        --download uniref uniref90_diamond \
        "${UNIREF_DB}"

fi


#############################################################
# UTILITY MAPPING
#############################################################

if find "${UTILITY_DB}" \
    -type f \
    -print -quit 2>/dev/null | grep -q .
then

    echo ""
    echo "Utility mapping database found."

else

    echo ""
    echo "Utility mapping database not found."
    echo "Downloading utility mapping..."
    echo ""

    "${HUMANN_DATABASES}" \
        --download utility_mapping full \
        "${UTILITY_DB}"

fi


#############################################################
# METAPHLAN DATABASE - MG-SHOTGUN
#############################################################

echo ""
echo "======================================"
echo "Checking MetaPhlAn database"
echo "MG-Shotgun / MetaPhlAn ${MG_METAPHLAN_VERSION}"
echo "======================================"


MG_DB_COMPLETE=true


for FILE in \
    "${METAPHLAN_DB}/mpa_vJan26_CHOCOPhlAnSGB_202605.1.bt2l" \
    "${METAPHLAN_DB}/mpa_vJan26_CHOCOPhlAnSGB_202605.2.bt2l" \
    "${METAPHLAN_DB}/mpa_vJan26_CHOCOPhlAnSGB_202605.3.bt2l" \
    "${METAPHLAN_DB}/mpa_vJan26_CHOCOPhlAnSGB_202605.4.bt2l" \
    "${METAPHLAN_DB}/mpa_vJan26_CHOCOPhlAnSGB_202605.rev.1.bt2l" \
    "${METAPHLAN_DB}/mpa_vJan26_CHOCOPhlAnSGB_202605.rev.2.bt2l"
do

    if [ ! -s "${FILE}" ]
    then
        MG_DB_COMPLETE=false
        break
    fi

done


if [ "${MG_DB_COMPLETE}" = true ]
then

    echo ""
    echo "MetaPhlAn MG-Shotgun database already present."
    echo "Skipping download."

else

    echo ""
    echo "MetaPhlAn MG-Shotgun database not found or incomplete."
    echo "Installing MetaPhlAn database..."
    echo ""

    "${METAPHLAN}" \
        --install \
        --db_dir "${METAPHLAN_DB}"

fi


#############################################################
# METAPHLAN DATABASE - HUMANN
#############################################################

echo ""
echo "======================================"
echo "Checking MetaPhlAn database"
echo "HUMAnN-func / MetaPhlAn ${HUMANN_METAPHLAN_VERSION}"
echo "======================================"


HUMANN_DB_COMPLETE=true


for FILE in \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.pkl" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.1.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.2.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.3.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.4.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.rev.1.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.rev.2.bt2l"
do

    if [ ! -s "${FILE}" ]
    then
        HUMANN_DB_COMPLETE=false
        break
    fi

done


if [ "${HUMANN_DB_COMPLETE}" = true ]
then

    echo ""
    echo "HUMAnN MetaPhlAn database already present."
    echo ""
    echo "Database:"
    echo "${HUMANN_METAPHLAN_INDEX}"

else

    echo ""
    echo "HUMAnN MetaPhlAn database not found or incomplete."
    echo ""
    echo "Installing:"
    echo "${HUMANN_METAPHLAN_INDEX}"
    echo ""
    echo "Database directory:"
    echo "${HUMANN_METAPHLAN_DB}"
    echo ""

    #########################################################
    # IMPORTANT
    #
    # Run MetaPhlAn inside HUMAnN-func so that
    # bowtie2-build and bowtie2-inspect are available
    # in the environment PATH.
    #########################################################

    "${CONDA}" run \
        -n HUMAnN-func \
        --no-capture-output \
        metaphlan \
        --install \
        --index "${HUMANN_METAPHLAN_INDEX}" \
        --bowtie2db "${HUMANN_METAPHLAN_DB}"

fi


#############################################################
# VERIFY HUMANN METAPHLAN DATABASE
#############################################################

echo ""
echo "Verifying HUMAnN MetaPhlAn database..."


for FILE in \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.pkl" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.1.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.2.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.3.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.4.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.rev.1.bt2l" \
    "${HUMANN_METAPHLAN_DB}/${HUMANN_METAPHLAN_INDEX}.rev.2.bt2l"
do

    if [ ! -s "${FILE}" ]
    then

        echo ""
        echo "ERROR: Missing HUMAnN MetaPhlAn database file:"
        echo "${FILE}"
        echo ""

        exit 1

    fi

done


echo ""
echo "HUMAnN MetaPhlAn database verified successfully."


#############################################################
# CONFIGURE HUMANN
#############################################################

echo ""
echo "======================================"
echo "Configuring HUMAnN"
echo "======================================"


"${HUMANN_CONFIG}" \
    --update database_folders nucleotide \
    "${CHOCOPHLAN_DB}"


"${HUMANN_CONFIG}" \
    --update database_folders protein \
    "${UNIREF_DB}"


"${HUMANN_CONFIG}" \
    --update database_folders utility_mapping \
    "${UTILITY_DB}"


"${HUMANN_CONFIG}" \
    --update run_modes threads 12


#############################################################
# HUMAN GENOME DATABASE
#############################################################

echo ""
echo "======================================"
echo "Checking human genome database"
echo "======================================"


HOST_INDEX="${HUMAN_DB_DIR}/human_GRCh38"

HOST_FASTA_GZ="${HUMAN_DB_DIR}/Homo_sapiens.GRCh38.dna.primary_assembly.fa.1.gz"

HOST_FASTA_TMP="${HUMAN_DB_DIR}/human_GRCh38_build_${BASHPID}.fa"


#############################################################
# CHECK COMPLETE BOWTIE2 INDEX
#############################################################

INDEX_COMPLETE=true


for FILE in \
    "${HOST_INDEX}.1.bt2" \
    "${HOST_INDEX}.2.bt2" \
    "${HOST_INDEX}.3.bt2" \
    "${HOST_INDEX}.4.bt2" \
    "${HOST_INDEX}.rev.1.bt2" \
    "${HOST_INDEX}.rev.2.bt2"
do

    if [ ! -s "${FILE}" ]
    then
        INDEX_COMPLETE=false
        break
    fi

done


#############################################################
# INDEX ALREADY PRESENT
#############################################################

if [ "${INDEX_COMPLETE}" = true ]
then

    echo ""
    echo "Human GRCh38 Bowtie2 database found."
    echo "Index already exists."
    echo "Skipping index construction."


#############################################################
# INDEX NOT PRESENT
#############################################################

else

    echo ""
    echo "Human GRCh38 Bowtie2 database not found."


    #########################################################
    # CHECK FASTA
    #########################################################

    if [ ! -s "${HOST_FASTA_GZ}" ]
    then

        echo ""
        echo "ERROR: GRCh38 FASTA not found:"
        echo "${HOST_FASTA_GZ}"
        echo ""

        exit 1

    fi


    echo ""
    echo "Checking GRCh38 FASTA..."


    if ! gzip -t "${HOST_FASTA_GZ}"
    then

        echo ""
        echo "ERROR: GRCh38 FASTA is corrupted:"
        echo "${HOST_FASTA_GZ}"
        echo ""

        exit 1

    fi


    echo "GRCh38 FASTA verified."


    #########################################################
    # BUILD BOWTIE2 INDEX
    #########################################################

    echo ""
    echo "Building human GRCh38 Bowtie2 index..."
    echo "Using MG-Shotgun environment."
    echo ""


    echo "Decompressing GRCh38 FASTA temporarily..."


    gzip -cd "${HOST_FASTA_GZ}" > "${HOST_FASTA_TMP}"


    "${CONDA}" run \
        -n MG-Shotgun \
        --no-capture-output \
        bowtie2-build \
        --threads 12 \
        "${HOST_FASTA_TMP}" \
        "${HOST_INDEX}"


    rm -f "${HOST_FASTA_TMP}"


    #########################################################
    # VERIFY INDEX
    #########################################################

    echo ""
    echo "Verifying human GRCh38 Bowtie2 index..."


    for FILE in \
        "${HOST_INDEX}.1.bt2" \
        "${HOST_INDEX}.2.bt2" \
        "${HOST_INDEX}.3.bt2" \
        "${HOST_INDEX}.4.bt2" \
        "${HOST_INDEX}.rev.1.bt2" \
        "${HOST_INDEX}.rev.2.bt2"
    do

        if [ ! -s "${FILE}" ]
        then

            echo ""
            echo "ERROR: Missing Bowtie2 index file:"
            echo "${FILE}"
            echo ""

            rm -f "${HOST_FASTA_TMP}"

            exit 1

        fi

    done


    echo ""
    echo "Human GRCh38 Bowtie2 database successfully created."

fi


#############################################################
# FINAL CHECK
#############################################################

echo ""
echo "======================================"
echo "FINAL ENVIRONMENT CHECK"
echo "======================================"


echo ""
echo "Conda executable:"
echo "${CONDA}"


echo ""
echo "MG-Shotgun:"
echo "${MG_ENV}"


echo ""
echo "HUMAnN-func:"
echo "${HUMANN_ENV}"


echo ""
echo "Python in HUMAnN-func:"
"${HUMANN_ENV}/bin/python" --version


echo ""
echo "HUMAnN:"
"${HUMANN}" --version


echo ""
echo "MG-Shotgun MetaPhlAn:"
"${METAPHLAN}" --version


echo ""
echo "HUMAnN MetaPhlAn:"
"${HUMANN_METAPHLAN}" --version


echo ""
echo "HUMAnN Bowtie2:"
"${HUMANN_BOWTIE2}" --version | head -1


echo ""
echo "HUMAnN MetaPhlAn database:"
echo "${HUMANN_METAPHLAN_DB}"


echo ""
echo "Human genome database:"
echo "${HUMAN_DB_DIR}"


#############################################################
# FINAL SUMMARY
#############################################################

echo ""
echo "======================================"
echo "PIPELINE SETUP COMPLETED"
echo "======================================"


echo ""
echo "IMPORTANT:"
echo ""
echo "- The Turing base environment was NOT modified."
echo "- No conda init was performed."
echo "- No conda update was performed."
echo "- No ~/.bashrc file was modified."
echo "- Existing MG-Shotgun was NOT modified."
echo "- Existing HUMAnN-func was NOT modified."
echo "- MG-Shotgun and HUMAnN MetaPhlAn databases are separate."
echo ""


echo "Project:"
echo "${PROJECT_DIR}"


echo ""
echo "======================================"