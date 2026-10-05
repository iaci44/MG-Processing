#!/bin/bash

#############################################################
# HUMAnN results merging
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
# HUMAnN utilities are called directly from the existing
# HUMAnN-func environment.
#
#############################################################

set -e


#############################################################
# HUMANN ENVIRONMENT
#############################################################

HUMANN_ENV="${HOME}/mambaforge/envs/HUMAnN-func"


HUMANN_JOIN="${HUMANN_ENV}/bin/humann_join_tables"

HUMANN_RENORM="${HUMANN_ENV}/bin/humann_renorm_table"

HUMANN_SPLIT="${HUMANN_ENV}/bin/humann_split_stratified_table"


#############################################################
# CHECK HUMANN TOOLS
#############################################################

if [ ! -x "${HUMANN_JOIN}" ]

then

    echo ""
    echo "ERROR: humann_join_tables not found:"
    echo "${HUMANN_JOIN}"

    exit 1

fi


if [ ! -x "${HUMANN_RENORM}" ]

then

    echo ""
    echo "ERROR: humann_renorm_table not found:"
    echo "${HUMANN_RENORM}"

    exit 1

fi


if [ ! -x "${HUMANN_SPLIT}" ]

then

    echo ""
    echo "ERROR: humann_split_stratified_table not found:"
    echo "${HUMANN_SPLIT}"

    exit 1

fi


#############################################################
# PROJECT NAME
#############################################################

if [ -z "$1" ]

then

    echo ""
    echo "Error: project name missing"
    echo ""
    echo "Usage:"
    echo "bash merge_results.sh PROJECT_NAME OUTPUT_DIRECTORY"
    echo ""

    exit 1

fi


PROJECT_NAME="$1"

PROJECT_DIR="${HOME}/${PROJECT_NAME}"

HUMANN_DIR="${PROJECT_DIR}/results/04_humann3"

PER_SAMPLE_DIR="${HUMANN_DIR}/per_sample"


#############################################################
# OUTPUT DIRECTORY
#############################################################

if [ -z "$2" ]

then

    echo ""
    echo "Error: output directory missing"
    echo ""
    echo "Usage:"
    echo "bash merge_results.sh PROJECT_NAME OUTPUT_DIRECTORY"
    echo ""
    echo "Example:"
    echo "bash merge_results.sh TEST_pipeline /home/biox/MG_results/TEST_pipeline"
    echo ""

    exit 1

fi


OUTPUT_DIR="$2"


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


if [ ! -d "${PER_SAMPLE_DIR}" ]

then

    echo ""
    echo "ERROR: HUMAnN per-sample directory not found:"
    echo "${PER_SAMPLE_DIR}"

    exit 1

fi


#############################################################
# CREATE OUTPUT DIRECTORY
#############################################################

mkdir -p "${OUTPUT_DIR}"


#############################################################
# TEMPORARY DIRECTORIES
#############################################################
#
# These directories are used only during the merge.
# They are deleted at the end.
#
#############################################################

TMP_DIR="${OUTPUT_DIR}/_merge_tmp"

GF_DIR="${TMP_DIR}/gf"

PA_DIR="${TMP_DIR}/pa"

PC_DIR="${TMP_DIR}/pc"


mkdir -p \
    "${GF_DIR}" \
    "${PA_DIR}" \
    "${PC_DIR}"


#############################################################
# HEADER
#############################################################

echo ""
echo "======================================"
echo " HUMAnN RESULTS MERGING"
echo "======================================"

echo ""
echo "Project:"
echo "${PROJECT_NAME}"

echo ""
echo "Input:"
echo "${PER_SAMPLE_DIR}"

echo ""
echo "Output:"
echo "${OUTPUT_DIR}"


#############################################################
# COLLECT GENE FAMILY FILES
#############################################################

echo ""
echo "======================================"
echo "Collecting gene family outputs"
echo "======================================"


GENEFAMILY_COUNT=0


while read -r FILE

do

    if [ -f "${FILE}" ]

    then

        cp "${FILE}" "${GF_DIR}/"

        GENEFAMILY_COUNT=$((GENEFAMILY_COUNT + 1))

    fi

done < <(
    find "${PER_SAMPLE_DIR}" \
        -mindepth 2 \
        -maxdepth 2 \
        -type f \
        -name "*_genefamilies.tsv" \
        | sort
)


echo ""
echo "Gene family files found:"
echo "${GENEFAMILY_COUNT}"


if [ "${GENEFAMILY_COUNT}" -eq 0 ]

then

    echo ""
    echo "ERROR: no gene family files found."

    rm -rf "${TMP_DIR}"

    exit 1

fi


#############################################################
# COLLECT PATHWAY ABUNDANCE FILES
#############################################################

echo ""
echo "======================================"
echo "Collecting pathway abundance outputs"
echo "======================================"


PATHABUNDANCE_COUNT=0


while read -r FILE

do

    if [ -f "${FILE}" ]

    then

        cp "${FILE}" "${PA_DIR}/"

        PATHABUNDANCE_COUNT=$((PATHABUNDANCE_COUNT + 1))

    fi

done < <(
    find "${PER_SAMPLE_DIR}" \
        -mindepth 2 \
        -maxdepth 2 \
        -type f \
        -name "*_pathabundance.tsv" \
        | sort
)


echo ""
echo "Pathway abundance files found:"
echo "${PATHABUNDANCE_COUNT}"


if [ "${PATHABUNDANCE_COUNT}" -eq 0 ]

then

    echo ""
    echo "WARNING: no pathway abundance files found."

fi


#############################################################
# COLLECT PATHWAY COVERAGE FILES
#############################################################

echo ""
echo "======================================"
echo "Collecting pathway coverage outputs"
echo "======================================"


PATHCOVERAGE_COUNT=0


while read -r FILE

do

    if [ -f "${FILE}" ]

    then

        cp "${FILE}" "${PC_DIR}/"

        PATHCOVERAGE_COUNT=$((PATHCOVERAGE_COUNT + 1))

    fi

done < <(
    find "${PER_SAMPLE_DIR}" \
        -mindepth 2 \
        -maxdepth 2 \
        -type f \
        -name "*_pathcoverage.tsv" \
        | sort
)


echo ""
echo "Pathway coverage files found:"
echo "${PATHCOVERAGE_COUNT}"


if [ "${PATHCOVERAGE_COUNT}" -eq 0 ]

then

    echo ""
    echo "WARNING: no pathway coverage files found."

fi


#############################################################
# JOIN GENE FAMILIES
#############################################################

echo ""
echo "======================================"
echo "Joining gene families"
echo "======================================"


"${HUMANN_JOIN}" \
    -i "${GF_DIR}" \
    -o "${OUTPUT_DIR}/genefamilies.tsv"


#############################################################
# JOIN PATHWAY ABUNDANCE
#############################################################

if [ "${PATHABUNDANCE_COUNT}" -gt 0 ]

then

    echo ""
    echo "======================================"
    echo "Joining pathway abundance"
    echo "======================================"


    "${HUMANN_JOIN}" \
        -i "${PA_DIR}" \
        -o "${OUTPUT_DIR}/pathabundance.tsv"

fi


#############################################################
# JOIN PATHWAY COVERAGE
#############################################################

if [ "${PATHCOVERAGE_COUNT}" -gt 0 ]

then

    echo ""
    echo "======================================"
    echo "Joining pathway coverage"
    echo "======================================"


    "${HUMANN_JOIN}" \
        -i "${PC_DIR}" \
        -o "${OUTPUT_DIR}/pathcoverage.tsv"

fi


#############################################################
# NORMALIZATION - CPM
#############################################################

echo ""
echo "======================================"
echo "Normalizing tables to CPM"
echo "======================================"


"${HUMANN_RENORM}" \
    -i "${OUTPUT_DIR}/genefamilies.tsv" \
    -o "${OUTPUT_DIR}/genefamilies_cpm.tsv" \
    --units cpm \
    --update-snames


if [ -f "${OUTPUT_DIR}/pathabundance.tsv" ]

then

    "${HUMANN_RENORM}" \
        -i "${OUTPUT_DIR}/pathabundance.tsv" \
        -o "${OUTPUT_DIR}/pathabundance_cpm.tsv" \
        --units cpm \
    --update-snames

fi


#############################################################
# SPLIT STRATIFIED GENE FAMILIES
#############################################################

echo ""
echo "======================================"
echo "Splitting stratified gene families"
echo "======================================"


"${HUMANN_SPLIT}" \
    -i "${OUTPUT_DIR}/genefamilies_cpm.tsv" \
    -o "${OUTPUT_DIR}"


#############################################################
# SPLIT STRATIFIED PATHWAY ABUNDANCE
#############################################################

if [ -f "${OUTPUT_DIR}/pathabundance_cpm.tsv" ]

then

    echo ""
    echo "Splitting stratified pathway abundance"


    "${HUMANN_SPLIT}" \
        -i "${OUTPUT_DIR}/pathabundance_cpm.tsv" \
        -o "${OUTPUT_DIR}"

fi


#############################################################
# REMOVE TEMPORARY FILES
#############################################################

echo ""
echo "Cleaning temporary files..."


rm -rf "${TMP_DIR}"


#############################################################
# OUTPUT SUMMARY
#############################################################

echo ""
echo "======================================"
echo " MERGE COMPLETED"
echo "======================================"


echo ""
echo "Results saved in:"
echo "${OUTPUT_DIR}"


echo ""
echo "Generated files:"


find "${OUTPUT_DIR}" \
    -maxdepth 1 \
    -type f \
    -printf "%f\n" \
    | sort


#############################################################
# FINAL MESSAGE
#############################################################

echo ""
echo "======================================"

echo "No conda command was executed."
echo "No mamba command was executed."
echo "No environment was activated."
echo "No Conda environment was modified."

echo "======================================"