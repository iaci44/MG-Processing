#!/bin/bash

#############################################################
# Shotgun Metagenomics Pipeline Configuration
#############################################################


#############################
# PROJECT
#############################

PROJECT_DIR=$HOME/PROJECT


#############################
# RESOURCES
#############################

THREADS=12



#############################
# INPUT / OUTPUT DIRECTORIES
#############################

RAW_DIR=${PROJECT_DIR}/raw_fastq

METADATA_DIR=${PROJECT_DIR}/metadata

RESULTS_DIR=${PROJECT_DIR}/results

LOG_DIR=${PROJECT_DIR}/logs

HUMANN_RESULTS_DIR=${RESULTS_DIR}/04_humann3



#############################
# DATABASES
#############################

# Human genome Bowtie2 index
HUMAN_DB=${HOME}/databases/host_human/human_GRCh38


# MetaPhlAn database
METAPHLAN_DB=${HOME}/databases/metaphlan


# HUMAnN databases
CHOCOPHLAN_DB=${HOME}/databases/chocophlan

UNIREF_DB=${HOME}/databases/uniref

UTILITY_DB=${HOME}/databases/utility_mapping



#############################
# SOFTWARE SETTINGS
#############################

# MetaPhlAn index used by HUMAnN
HUMANN_INDEX="mpa_vJun23_CHOCOPhlAnSGB_202403"