#!/bin/bash

#############################################################
# HUMAnN restart / fix stuck sample
#############################################################
#
# IMPORTANT:
#
# This script:
#
#   - NEVER runs conda
#   - NEVER runs mamba
#   - NEVER activates an environment
#   - NEVER modifies ~/.bashrc
#   - NEVER modifies any Conda environment
#
# Only the selected PROJECT and SAMPLE are affected.
#
#############################################################

set -e


#############################################################
# HUMANN ENVIRONMENT
#############################################################

HUMANN_ENV="${HOME}/mambaforge/envs/HUMAnN-func"

HUMANN="${HUMANN_ENV}/bin/humann"

HUMANN_METAPHLAN="${HUMANN_ENV}/bin/metaphlan"

HUMANN_BOWTIE2="${HUMANN_ENV}/bin/bowtie2"

HUMANN_DIAMOND="${HUMANN_ENV}/bin/diamond"


#############################################################
# PROJECT NAME
#############################################################

if [ -z "$1" ]

then

    echo ""
    echo "Error: project name missing"
    echo ""
    echo "Usage:"
    echo "bash restart_humann.sh PROJECT_NAME SAMPLE_NAME"
    echo ""
    echo "Example:"
    echo "bash restart_humann.sh TEST_pipeline mgshot_S16781Nr1"
    echo ""

    exit 1

fi


PROJECT_NAME="$1"


#############################################################
# SAMPLE NAME
#############################################################

if [ -z "$2" ]

then

    echo ""
    echo "Error: sample name missing"
    echo ""
    echo "Usage:"
    echo "bash restart_humann.sh PROJECT_NAME SAMPLE_NAME"
    echo ""
    echo "Example:"
    echo "bash restart_humann.sh TEST_pipeline mgshot_S16781Nr1"
    echo ""

    exit 1

fi


SAMPLE="$2"


#############################################################
# LOAD CONFIGURATION
#############################################################

PROJECT_DIR="${HOME}/${PROJECT_NAME}"

CONFIG_FILE="$(dirname "$0")/config/config.sh"


if [ ! -f "${CONFIG_FILE}" ]

then

    echo ""
    echo "ERROR: configuration file not found:"
    echo "${CONFIG_FILE}"

    exit 1

fi


source "${CONFIG_FILE}"


#############################################################
# DIRECTORIES
#############################################################

IN="${PROJECT_DIR}/results/02_host_removed"

OUT="${PROJECT_DIR}/results/04_humann3"

SAMPLE_OUT="${OUT}/per_sample/${SAMPLE}"

LOG_DIR="${PROJECT_DIR}/logs"

SAMPLE_LOG="${OUT}/logs/${SAMPLE}_restart.log"


#############################################################
# HEADER
#############################################################

echo ""
echo "======================================"
echo " Restarting stuck HUMAnN sample"
echo "======================================"


echo ""
echo "Project:"
echo "${PROJECT_NAME}"


echo ""
echo "Sample:"
echo "${SAMPLE}"


echo ""
echo "Project directory:"
echo "${PROJECT_DIR}"


#############################################################
# CHECK HUMANN
#############################################################

if [ ! -x "${HUMANN}" ]

then

    echo ""
    echo "ERROR: HUMAnN executable not found:"
    echo "${HUMANN}"

    exit 1

fi


#############################################################
# CHECK PROJECT
#############################################################

if [ ! -d "${PROJECT_DIR}" ]

then

    echo ""
    echo "ERROR: project directory not found:"
    echo "${PROJECT_DIR}"

    exit 1

fi


#############################################################
# CHECK INPUT FASTQ
#############################################################

R1="${IN}/${SAMPLE}_clean.1.fastq.gz"

R2="${IN}/${SAMPLE}_clean.2.fastq.gz"


if [ ! -f "${R1}" ]

then

    echo ""
    echo "ERROR: forward FASTQ not found:"
    echo "${R1}"

    exit 1

fi


if [ ! -f "${R2}" ]

then

    echo ""
    echo "ERROR: reverse FASTQ not found:"
    echo "${R2}"

    exit 1

fi


#############################################################
# CHECK DATABASES
#############################################################

if [ ! -d "${HUMANN_METAPHLAN_DB}" ]

then

    echo ""
    echo "ERROR: HUMAnN MetaPhlAn database not found:"
    echo "${HUMANN_METAPHLAN_DB}"

    exit 1

fi


if [ ! -f "${HUMANN_METAPHLAN_DB}/${HUMANN_INDEX}.pkl" ]

then

    echo ""
    echo "ERROR: HUMAnN MetaPhlAn index not found:"
    echo "${HUMANN_INDEX}"

    exit 1

fi


#############################################################
# CREATE DIRECTORIES
#############################################################

mkdir -p "${SAMPLE_OUT}"

mkdir -p "${OUT}/logs"

mkdir -p "${LOG_DIR}"


#############################################################
# CHECK FOR RUNNING PROCESS OF THIS SAMPLE
#############################################################

echo ""
echo "Checking for running processes belonging to:"
echo "${SAMPLE}"


SAMPLE_PROCESSES=$(
    ps -eo pid=,cmd= \
    | grep -F "${SAMPLE}" \
    | grep -E 'humann|bowtie2|diamond' \
    | grep -v grep \
    || true
)


if [ -n "${SAMPLE_PROCESSES}" ]

then

    echo ""
    echo "Processes found:"
    echo ""
    echo "${SAMPLE_PROCESSES}"


    echo ""
    echo "Stopping processes belonging to this sample..."


    SAMPLE_PIDS=$(
        echo "${SAMPLE_PROCESSES}" \
        | awk '{print $1}'
    )


    for PID in ${SAMPLE_PIDS}

    do

        if [ "${PID}" != "$$" ]

        then

            echo "Stopping PID ${PID}"

            kill -TERM "${PID}" 2>/dev/null || true

        fi

    done


    sleep 5


    #########################################################
    # FORCE KILL ONLY IF STILL RUNNING
    #########################################################

    SAMPLE_PROCESSES_AFTER=$(
        ps -eo pid=,cmd= \
        | grep -F "${SAMPLE}" \
        | grep -E 'humann|bowtie2|diamond' \
        | grep -v grep \
        || true
    )


    if [ -n "${SAMPLE_PROCESSES_AFTER}" ]

    then

        echo ""
        echo "Some processes are still running."
        echo "Forcing termination..."


        SAMPLE_PIDS_AFTER=$(
            echo "${SAMPLE_PROCESSES_AFTER}" \
            | awk '{print $1}'
        )


        for PID in ${SAMPLE_PIDS_AFTER}

        do

            if [ "${PID}" != "$$" ]

            then

                kill -9 "${PID}" 2>/dev/null || true

            fi

        done

    fi


else

    echo ""
    echo "No running HUMAnN process found for this sample."

fi


#############################################################
# CLEAN INTERRUPTED SAMPLE
#############################################################

echo ""
echo "Cleaning interrupted sample..."


rm -rf \
    "${SAMPLE_OUT}/${SAMPLE}_humann_temp"*


rm -rf \
    "${SAMPLE_OUT}/temp"


rm -f \
    "${SAMPLE_OUT}/${SAMPLE}_concat.fastq.gz"


#############################################################
# REMOVE INCOMPLETE OUTPUTS
#############################################################

echo ""
echo "Checking existing HUMAnN output..."


if [ -f "${SAMPLE_OUT}/${SAMPLE}_genefamilies.tsv" ]

then

    echo ""
    echo "A gene families file already exists."

    echo "The sample may already be completed."

    echo ""
    echo "If you really want to rerun it, remove the existing"
    echo "HUMAnN output manually before restarting."

    exit 1

fi


#############################################################
# CREATE CONCATENATED FASTQ
#############################################################

echo ""
echo "Creating concatenated FASTQ..."

echo ""
echo "Input R1:"
echo "${R1}"

echo ""
echo "Input R2:"
echo "${R2}"


cat \
    <(zcat "${R1}") \
    <(zcat "${R2}") \
    | gzip > "${SAMPLE_OUT}/${SAMPLE}_concat.fastq.gz"


#############################################################
# CHECK CONCATENATED FASTQ
#############################################################

if [ ! -s "${SAMPLE_OUT}/${SAMPLE}_concat.fastq.gz" ]

then

    echo ""
    echo "ERROR: concatenated FASTQ is empty."

    rm -f "${SAMPLE_OUT}/${SAMPLE}_concat.fastq.gz"

    exit 1

fi


echo ""
echo "Concatenated FASTQ created."


#############################################################
# HUMANN COMMAND
#############################################################

echo ""
echo "======================================"
echo "Starting HUMAnN"
echo "======================================"


echo ""
echo "HUMAnN executable:"
echo "${HUMANN}"


echo ""
echo "HUMAnN version:"

"${HUMANN}" --version


echo ""
echo "Threads:"
echo "${THREADS}"


echo ""
echo "MetaPhlAn database:"
echo "${HUMANN_METAPHLAN_DB}"


echo ""
echo "MetaPhlAn index:"
echo "${HUMANN_INDEX}"


#############################################################
# RUN HUMANN
#############################################################

"${HUMANN}" \
    --input "${SAMPLE_OUT}/${SAMPLE}_concat.fastq.gz" \
    --output "${SAMPLE_OUT}" \
    --output-basename "${SAMPLE}" \
    --threads "${THREADS}" \
    --memory-use minimum \
    --metaphlan "${HUMANN_METAPHLAN}" \
    --bowtie2 "${HUMANN_BOWTIE2}" \
    --diamond "${HUMANN_DIAMOND}" \
    --metaphlan-options "--bowtie2db ${HUMANN_METAPHLAN_DB} --index ${HUMANN_INDEX} --nproc ${THREADS}" \
    --remove-temp-output \
    --o-log "${SAMPLE_LOG}"


#############################################################
# REMOVE CONCATENATED FASTQ
#############################################################

rm -f \
    "${SAMPLE_OUT}/${SAMPLE}_concat.fastq.gz"


#############################################################
# CHECK RESULT
#############################################################

echo ""
echo "Checking HUMAnN result..."


if [ -s "${SAMPLE_OUT}/${SAMPLE}_genefamilies.tsv" ]

then

    echo ""
    echo "======================================"
    echo " HUMAnN restart completed successfully"
    echo "======================================"

    echo ""
    echo "Sample:"
    echo "${SAMPLE}"

    echo ""
    echo "Output:"
    echo "${SAMPLE_OUT}"

else

    echo ""
    echo "======================================"
    echo " HUMAnN restart FAILED"
    echo "======================================"

    echo ""
    echo "Check log:"
    echo "${SAMPLE_LOG}"

    exit 1

fi


#############################################################
# FINAL MESSAGE
#############################################################

echo ""
echo "No conda command was executed."
echo "No mamba command was executed."
echo "No environment was activated."
echo "No Conda environment was modified."

echo ""