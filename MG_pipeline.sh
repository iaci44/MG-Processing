#!/bin/bash

#############################################################
# Shotgun Metagenomics Pipeline
#############################################################
#
# IMPORTANT:
#
# - This script NEVER runs conda
# - This script NEVER runs mamba
# - This script NEVER activates an environment
# - This script NEVER modifies ~/.bashrc
# - The Turing base environment is NOT used
#
# Existing environments:
#
#   /home/biox/mambaforge/envs/MG-Shotgun
#   /home/biox/mambaforge/envs/HUMAnN-func
#
#############################################################

set -e


#############################################################
# LOAD CONFIGURATION
#############################################################

source config/config.sh


#############################################################
# PIPELINE ENVIRONMENTS
#############################################################

MG_ENV="${HOME}/mambaforge/envs/MG-Shotgun"

HUMANN_ENV="${HOME}/mambaforge/envs/HUMAnN-func"


#############################################################
# SOFTWARE PATHS
#############################################################

FASTQC="${MG_ENV}/bin/fastqc"

FASTP="${MG_ENV}/bin/fastp"

BOWTIE2="${MG_ENV}/bin/bowtie2"

METAPHLAN="${MG_ENV}/bin/metaphlan"

MERGE_METAPHLAN="${MG_ENV}/bin/merge_metaphlan_tables.py"

SAMTOOLS="${MG_ENV}/bin/samtools"


HUMANN="${HUMANN_ENV}/bin/humann"

HUMANN_METAPHLAN="${HUMANN_ENV}/bin/metaphlan"

HUMANN_BOWTIE2="${HUMANN_ENV}/bin/bowtie2"

HUMANN_DIAMOND="${HUMANN_ENV}/bin/diamond"


#############################################################
# CHECK ENVIRONMENTS
#############################################################

echo ""
echo "======================================"
echo "Checking pipeline environments"
echo "======================================"


if [ ! -d "${MG_ENV}" ]

then

    echo "ERROR: MG-Shotgun environment not found:"
    echo "${MG_ENV}"

    exit 1

fi


if [ ! -d "${HUMANN_ENV}" ]

then

    echo "ERROR: HUMAnN-func environment not found:"
    echo "${HUMANN_ENV}"

    exit 1

fi


#############################################################
# CHECK SOFTWARE
#############################################################

echo ""
echo "Checking MG-Shotgun tools..."


if [ ! -x "${FASTQC}" ]

then

    echo "ERROR: FastQC not found:"
    echo "${FASTQC}"

    exit 1

fi


if [ ! -x "${FASTP}" ]

then

    echo "ERROR: fastp not found:"
    echo "${FASTP}"

    exit 1

fi


if [ ! -x "${BOWTIE2}" ]

then

    echo "ERROR: Bowtie2 not found:"
    echo "${BOWTIE2}"

    exit 1

fi


if [ ! -x "${METAPHLAN}" ]

then

    echo "ERROR: MetaPhlAn not found:"
    echo "${METAPHLAN}"

    exit 1

fi


if [ ! -x "${MERGE_METAPHLAN}" ]

then

    echo "ERROR: merge_metaphlan_tables.py not found:"
    echo "${MERGE_METAPHLAN}"

    exit 1

fi


echo ""
echo "Checking HUMAnN-func tools..."


if [ ! -x "${HUMANN}" ]

then

    echo "ERROR: HUMAnN not found:"
    echo "${HUMANN}"

    exit 1

fi


if [ ! -x "${HUMANN_METAPHLAN}" ]

then

    echo "ERROR: MetaPhlAn inside HUMAnN-func not found:"
    echo "${HUMANN_METAPHLAN}"

    exit 1

fi


if [ ! -x "${HUMANN_BOWTIE2}" ]

then

    echo "ERROR: Bowtie2 inside HUMAnN-func not found:"
    echo "${HUMANN_BOWTIE2}"

    exit 1

fi


if [ ! -x "${HUMANN_DIAMOND}" ]

then

    echo "ERROR: DIAMOND inside HUMAnN-func not found:"
    echo "${HUMANN_DIAMOND}"

    exit 1

fi


#############################################################
# PRINT SOFTWARE VERSIONS
#############################################################

echo ""
echo "======================================"
echo "Pipeline software"
echo "======================================"


echo ""
echo "MetaPhlAn - MG-Shotgun:"
"${METAPHLAN}" --version


echo ""
echo "Bowtie2 - MG-Shotgun:"
"${BOWTIE2}" --version | head -1


echo ""
echo "HUMAnN:"
"${HUMANN}" --version


echo ""
echo "MetaPhlAn - HUMAnN-func:"
"${HUMANN_METAPHLAN}" --version


echo ""
echo "DIAMOND:"
"${HUMANN_DIAMOND}" version


#############################################################
# PROJECT NAME
#############################################################

if [ -z "$1" ]

then

    echo ""
    echo "Error: project name missing"
    echo ""
    echo "Usage:"
    echo "bash MG_pipeline.sh PROJECT_NAME"

    exit 1

fi


PROJECT_NAME="$1"

PROJECT_DIR="${HOME}/${PROJECT_NAME}"


#############################################################
# PROJECT INFORMATION
#############################################################

echo ""
echo "======================================"
echo "Running project"
echo "======================================"


echo ""
echo "Project:"
echo "${PROJECT_NAME}"


echo ""
echo "Project directory:"
echo "${PROJECT_DIR}"


#############################################################
# CREATE DIRECTORIES
#############################################################

mkdir -p "${PROJECT_DIR}/metadata"

mkdir -p "${PROJECT_DIR}/results/01_qc"

mkdir -p "${PROJECT_DIR}/results/02_host_removed"

mkdir -p "${PROJECT_DIR}/results/03_metaphlan"

mkdir -p "${PROJECT_DIR}/results/04_humann3"

mkdir -p "${PROJECT_DIR}/logs"


#############################################################
# CHECK RAW FASTQ DIRECTORY
#############################################################

if [ ! -d "${PROJECT_DIR}/raw_fastq" ]

then

    echo ""
    echo "ERROR: raw_fastq directory not found:"
    echo "${PROJECT_DIR}/raw_fastq"

    exit 1

fi


if ! compgen -G "${PROJECT_DIR}/raw_fastq/*.1.fastq.gz" > /dev/null

then

    echo ""
    echo "ERROR: no paired-end FASTQ files found."
    echo ""
    echo "Expected files such as:"
    echo "sample01.1.fastq.gz"
    echo "sample01.2.fastq.gz"

    exit 1

fi


#############################################################
# LIST SAMPLES
#############################################################

echo ""
echo "======================================"
echo "Creating sample list"
echo "======================================"


cd "${PROJECT_DIR}"


find "${PROJECT_DIR}/raw_fastq" \
    -maxdepth 1 \
    -type f \
    -name "*.1.fastq.gz" \
    -printf "%f\n" \
    | sed 's/\.1\.fastq\.gz$//' \
    | sort \
    > "${PROJECT_DIR}/metadata/samples.txt"


echo ""
echo "Number of samples:"

wc -l "${PROJECT_DIR}/metadata/samples.txt"


echo ""
echo "Samples detected:"

cat "${PROJECT_DIR}/metadata/samples.txt"


#############################################################
# STEP 1 - QUALITY CONTROL
#############################################################

echo ""
echo "======================================"
echo "STEP 1 - QUALITY CONTROL"
echo "======================================"


"${FASTQC}" \
    -t "${THREADS}" \
    -o "${PROJECT_DIR}/results/01_qc" \
    "${PROJECT_DIR}"/raw_fastq/*.fastq.gz


echo ""
echo "FastQC completed"


#############################################################
# OPTIONAL TRIMMING
#############################################################

RUN_TRIMMING=false


if [ "${RUN_TRIMMING}" = true ]

then

    echo ""
    echo "Running fastp trimming"


    while read -r S

    do

        "${FASTP}" \
            -i "${PROJECT_DIR}/raw_fastq/${S}.1.fastq.gz" \
            -I "${PROJECT_DIR}/raw_fastq/${S}.2.fastq.gz" \
            -o "${PROJECT_DIR}/results/01_qc/${S}_trim.1.fastq.gz" \
            -O "${PROJECT_DIR}/results/01_qc/${S}_trim.2.fastq.gz" \
            --detect_adapter_for_pe \
            --qualified_quality_phred 20 \
            --length_required 20 \
            --thread "${THREADS}" \
            -h "${PROJECT_DIR}/results/01_qc/${S}_fastp.html"


    done < "${PROJECT_DIR}/metadata/samples.txt"


else

    echo ""
    echo "Trimming skipped"

fi


#############################################################
# STEP 2 - REMOVE HOST READS
#############################################################

echo ""
echo "======================================"
echo "STEP 2 - HOST REMOVAL"
echo "======================================"


HOST="${HUMAN_DB}"

if ! compgen -G "${HOST}.1.bt2*" > /dev/null
then

    echo ""
    echo "ERROR: human genome Bowtie2 index not found."
    echo ""
    echo "Expected:"
    echo "${HOST}.1.bt2 or ${HOST}.1.bt2l"

    exit 1

fi

while read -r S

do

    if [ -s "${PROJECT_DIR}/results/02_host_removed/${S}_clean.1.fastq.gz" ] && \
   [ -s "${PROJECT_DIR}/results/02_host_removed/${S}_clean.2.fastq.gz" ]

    then

        echo ""
        echo "Skipping ${S}: already processed"

        continue

    fi


    echo ""
    echo "Removing host reads: ${S}"


    "${BOWTIE2}" \
        -x "${HOST}" \
        -1 "${PROJECT_DIR}/raw_fastq/${S}.1.fastq.gz" \
        -2 "${PROJECT_DIR}/raw_fastq/${S}.2.fastq.gz" \
        -p "${THREADS}" \
        --very-sensitive \
        --un-conc-gz "${PROJECT_DIR}/results/02_host_removed/${S}_clean.%.fastq.gz" \
        -S /dev/null \
        2> "${PROJECT_DIR}/logs/${S}_host.log"


done < "${PROJECT_DIR}/metadata/samples.txt"


echo ""
echo "Host removal completed"


#############################################################
# STEP 3 - METAPHLAN TAXONOMIC PROFILING
#############################################################

echo ""
echo "======================================"
echo "STEP 3 - METAPHLAN"
echo "======================================"


#############################################################
# IMPORTANT:
#
# This MetaPhlAn run uses:
#
# MG-Shotgun
# MetaPhlAn 4.2.5
# Database:
# ${METAPHLAN_DB}
#
# MetaPhlAn >=4.2 uses --db_dir.
#
#############################################################

if [ ! -d "${METAPHLAN_DB}" ]

then

    echo ""
    echo "ERROR: MetaPhlAn database directory not found:"
    echo "${METAPHLAN_DB}"

    exit 1

fi


while read -r S

do

    if [ -s "${PROJECT_DIR}/results/03_metaphlan/${S}_profile.tsv" ]

    then

        echo ""
        echo "Skipping ${S}: MetaPhlAn already completed"

        continue

    fi


    echo ""
    echo "Running MetaPhlAn: ${S}"


    PATH="${MG_ENV}/bin:${PATH}" "${METAPHLAN}" \
    "${PROJECT_DIR}/results/02_host_removed/${S}_clean.1.fastq.gz,${PROJECT_DIR}/results/02_host_removed/${S}_clean.2.fastq.gz" \
    --input_type fastq \
        --db_dir "${METAPHLAN_DB}" \
        --mapout "${PROJECT_DIR}/results/03_metaphlan/${S}_bt2.bz2" \
        --nproc "${THREADS}" \
        -t rel_ab_w_read_stats \
        -o "${PROJECT_DIR}/results/03_metaphlan/${S}_profile.tsv"


done < "${PROJECT_DIR}/metadata/samples.txt"


#############################################################
# MERGE METAPHLAN RESULTS
#############################################################

echo ""
echo "Merging MetaPhlAn tables..."


"${MERGE_METAPHLAN}" \
    "${PROJECT_DIR}/results/03_metaphlan/"*_profile.tsv \
    > "${PROJECT_DIR}/results/03_metaphlan/merged_abundance_table.tsv"


echo ""
echo "MetaPhlAn completed"


#############################################################
# STEP 4 - HUMANN FUNCTIONAL PROFILING
#############################################################

echo ""
echo "======================================"
echo "STEP 4 - HUMANN"
echo "======================================"


IN="${PROJECT_DIR}/results/02_host_removed"

OUT="${PROJECT_DIR}/results/04_humann3"


mkdir -p "${OUT}/per_sample"

mkdir -p "${OUT}/logs"


#############################################################
# CHECK HUMANN METAPHLAN DATABASE
#############################################################
#
# HUMAnN 3.9 uses:
#
# MetaPhlAn 4.1.2
#
# Database:
#
# ${HUMANN_METAPHLAN_DB}
#
# Index:
#
# ${HUMANN_INDEX}
#
# MetaPhlAn 4.1.2 uses --bowtie2db.
#
#############################################################

if [ ! -d "${HUMANN_METAPHLAN_DB}" ]

then

    echo ""
    echo "ERROR: HUMAnN MetaPhlAn database directory not found:"
    echo "${HUMANN_METAPHLAN_DB}"

    exit 1

fi


if [ ! -f "${HUMANN_METAPHLAN_DB}/${HUMANN_INDEX}.pkl" ]

then

    echo ""
    echo "ERROR: HUMAnN MetaPhlAn database index not found:"
    echo "${HUMANN_INDEX}"

    echo ""
    echo "Expected:"
    echo "${HUMANN_METAPHLAN_DB}/${HUMANN_INDEX}.pkl"

    exit 1

fi


if ! compgen -G "${HUMANN_METAPHLAN_DB}/${HUMANN_INDEX}.1.bt2l" > /dev/null

then

    echo ""
    echo "ERROR: HUMAnN MetaPhlAn Bowtie2 index not found."

    echo ""
    echo "Expected:"
    echo "${HUMANN_METAPHLAN_DB}/${HUMANN_INDEX}.1.bt2l"

    exit 1

fi


#############################################################
# SORT SAMPLES BY INPUT FILE SIZE
#############################################################

SORTED=$(
    while read -r S

    do

        FILE="${IN}/${S}_clean.1.fastq.gz"


        if [ -f "${FILE}" ]

        then

            echo "$(du -k "${FILE}" | cut -f1) ${S}"

        fi


    done < "${PROJECT_DIR}/metadata/samples.txt" \
    | sort -n \
    | awk '{print $2}'
)


#############################################################
# RUN HUMANN
#############################################################

for S in ${SORTED}

do

    SAMPLE_OUT="${OUT}/per_sample/${S}"


    if ls "${SAMPLE_OUT}"/*_genefamilies.tsv 1>/dev/null 2>&1

    then

        echo ""
        echo "Skipping ${S}: already completed"

        continue

    fi


    mkdir -p "${SAMPLE_OUT}"


    echo ""
    echo "Running HUMAnN: ${S}"


    #########################################################
    # CREATE INTERLEAVED FASTQ
    #########################################################

    cat \
        <(zcat "${IN}/${S}_clean.1.fastq.gz") \
        <(zcat "${IN}/${S}_clean.2.fastq.gz") \
        | gzip > "${SAMPLE_OUT}/${S}_concat.fastq.gz"


    #########################################################
    # RUN HUMANN
    #########################################################

"${HUMANN}" \
    --input "${SAMPLE_OUT}/${S}_concat.fastq.gz" \
    --output "${SAMPLE_OUT}" \
    --output-basename "${S}" \
    --threads "${THREADS}" \
    --memory-use minimum \
    --metaphlan "${HUMANN_ENV}/bin" \
    --bowtie2 "${HUMANN_ENV}/bin" \
    --diamond "${HUMANN_ENV}/bin" \
    --metaphlan-options "--bowtie2db ${HUMANN_METAPHLAN_DB} --index ${HUMANN_INDEX} --nproc ${THREADS} --offline" \
    --remove-temp-output \
    --o-log "${OUT}/logs/${S}.log"

    #########################################################
    # REMOVE TEMPORARY CONCATENATED FASTQ
    #########################################################

    rm -f "${SAMPLE_OUT}/${S}_concat.fastq.gz"


done


echo ""
echo "HUMAnN completed"


#############################################################
# FINAL MESSAGE
#############################################################

echo ""
echo "======================================"
echo "PIPELINE COMPLETED"
echo "======================================"


echo ""
echo "Project:"
echo "${PROJECT_NAME}"


echo ""
echo "Results:"
echo "${PROJECT_DIR}/results"


echo ""
echo "Software environments used:"
echo "${MG_ENV}"
echo "${HUMANN_ENV}"


echo ""
echo "MetaPhlAn database:"
echo "${METAPHLAN_DB}"


echo ""
echo "HUMAnN MetaPhlAn database:"
echo "${HUMANN_METAPHLAN_DB}"


echo ""
echo "HUMAnN MetaPhlAn index:"
echo "${HUMANN_INDEX}"


echo ""
echo "No conda command was executed."
echo "No mamba command was executed."
echo "No environment was activated."
echo "The Turing base environment was not used or modified."


echo ""