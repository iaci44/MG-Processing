#!/bin/bash

#############################################################
# HUMAnN / Pipeline Monitoring Script
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
# HUMAnN is monitored directly from the existing
# HUMAnN-func environment.
#
#############################################################


#############################################################
# SETTINGS
#############################################################

HUMANN_ENV="${HOME}/mambaforge/envs/HUMAnN-func"

HUMANN="${HUMANN_ENV}/bin/humann"


#############################################################
# PROJECT NAME
#############################################################

if [ -z "$1" ]

then

    echo ""
    echo "Error: project name missing"
    echo ""
    echo "Usage:"
    echo "bash monitor_humann.sh PROJECT_NAME"
    echo ""

    exit 1

fi


PROJECT_NAME="$1"

PROJECT_DIR="${HOME}/${PROJECT_NAME}"


#############################################################
# PROJECT DIRECTORIES
#############################################################

LOG_DIR="${PROJECT_DIR}/logs"

HUMANN_DIR="${PROJECT_DIR}/results/04_humann3"

PER_SAMPLE_DIR="${HUMANN_DIR}/per_sample"


#############################################################
# HEADER
#############################################################

echo ""
echo "======================================"
echo " HUMAnN / Pipeline monitoring"
echo "======================================"

echo ""
echo "Project:"
echo "${PROJECT_NAME}"

echo ""
echo "Project directory:"
echo "${PROJECT_DIR}"


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
# CHECK HUMANN INSTALLATION
#############################################################

if [ ! -x "${HUMANN}" ]

then

    echo ""
    echo "ERROR: HUMAnN executable not found:"
    echo "${HUMANN}"

    exit 1

fi


#############################################################
# HUMANN VERSION
#############################################################

echo ""
echo "HUMAnN executable:"
echo "${HUMANN}"

echo ""
echo "HUMAnN version:"

"${HUMANN}" --version


#############################################################
# CHECK RUNNING HUMANN PROCESSES
#############################################################

echo ""
echo "======================================"
echo "Running HUMAnN processes"
echo "======================================"


HUMANN_PROCESSES=$(
    pgrep -af "${HUMANN}" 2>/dev/null || true
)


if [ -n "${HUMANN_PROCESSES}" ]

then

    echo ""
    echo "HUMAnN processes currently running:"
    echo ""

    echo "${HUMANN_PROCESSES}"

else

    echo ""
    echo "No HUMAnN process currently running."

fi


#############################################################
# COUNT HUMANN PROCESSES
#############################################################

HUMANN_COUNT=$(
    pgrep -fc "${HUMANN}" 2>/dev/null || true
)


echo ""
echo "Number of running HUMAnN processes:"
echo "${HUMANN_COUNT}"


#############################################################
# SHOW PIPELINE LOG
#############################################################

echo ""
echo "======================================"
echo "Pipeline log"
echo "======================================"


PIPELINE_LOG="${LOG_DIR}/pipeline.log"


if [ -f "${PIPELINE_LOG}" ]

then

    echo ""
    echo "Last 20 lines of:"
    echo "${PIPELINE_LOG}"

    echo ""

    tail -20 "${PIPELINE_LOG}"

else

    echo ""
    echo "Pipeline log not found:"
    echo "${PIPELINE_LOG}"

    echo ""
    echo "This is not necessarily an error."
    echo "The pipeline may have been started without redirecting"
    echo "stdout/stderr to pipeline.log."

fi


#############################################################
# COUNT COMPLETED SAMPLES
#############################################################

echo ""
echo "======================================"
echo "Completed HUMAnN samples"
echo "======================================"


if [ -d "${PER_SAMPLE_DIR}" ]

then

    COMPLETED_SAMPLES=$(
        find "${PER_SAMPLE_DIR}" \
            -mindepth 2 \
            -maxdepth 2 \
            -type f \
            -name "*_genefamilies.tsv" \
            | wc -l
    )

else

    COMPLETED_SAMPLES=0

fi


echo ""
echo "Completed samples:"
echo "${COMPLETED_SAMPLES}"


#############################################################
# LIST COMPLETED SAMPLES
#############################################################

if [ "${COMPLETED_SAMPLES}" -gt 0 ]

then

    echo ""
    echo "Completed sample files:"

    find "${PER_SAMPLE_DIR}" \
        -mindepth 2 \
        -maxdepth 2 \
        -type f \
        -name "*_genefamilies.tsv" \
        | sort

fi


#############################################################
# CHECK PIPELINE PID
#############################################################

echo ""
echo "======================================"
echo "Pipeline status"
echo "======================================"


PID_FILE="${LOG_DIR}/pipeline.pid"


if [ -f "${PID_FILE}" ]

then

    PID=$(cat "${PID_FILE}")


    if [ -z "${PID}" ]

    then

        echo ""
        echo "PID file exists but is empty."

    elif [[ "${PID}" =~ ^[0-9]+$ ]]

    then

        if ps -p "${PID}" > /dev/null 2>&1

        then

            echo ""
            echo "Pipeline process is still running."

            echo "PID:"
            echo "${PID}"

        else

            echo ""
            echo "Pipeline process is not running."

            echo "PID:"
            echo "${PID}"

        fi

    else

        echo ""
        echo "Invalid PID found in:"
        echo "${PID_FILE}"

    fi

else

    echo ""
    echo "PID file not found:"
    echo "${PID_FILE}"

    echo ""
    echo "This is not necessarily an error."
    echo "A PID file is only available if the pipeline was"
    echo "started with one."

fi


#############################################################
# CHECK HUMANN OUTPUT DIRECTORY
#############################################################

echo ""
echo "======================================"
echo "HUMAnN output directory"
echo "======================================"


if [ -d "${HUMANN_DIR}" ]

then

    echo ""
    echo "${HUMANN_DIR}"

    echo ""
    echo "Current contents:"

    find "${HUMANN_DIR}" \
        -maxdepth 2 \
        -type d \
        | sort

else

    echo ""
    echo "HUMAnN output directory not found:"
    echo "${HUMANN_DIR}"

fi


#############################################################
# FINAL STATUS
#############################################################

echo ""
echo "======================================"
echo "Monitoring completed"
echo "======================================"

echo ""
echo "No conda command was executed."
echo "No mamba command was executed."
echo "No environment was activated."
echo "No Conda environment was modified."

echo ""