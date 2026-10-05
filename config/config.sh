#!/bin/bash

#############################################################
# Shotgun Metagenomics Pipeline Configuration
#############################################################
#
# This file contains pipeline parameters and database paths.
#
# Conda environments are managed separately by install.sh.
#
# Reference databases are stored in a shared directory and
# reused across different analysis projects.
#
#############################################################


#############################################################
# RESOURCES
#############################################################

THREADS=12


#############################################################
# INPUT / OUTPUT DIRECTORIES
#############################################################

RAW_DIR="${PROJECT_DIR}/raw_fastq"

METADATA_DIR="${PROJECT_DIR}/metadata"

RESULTS_DIR="${PROJECT_DIR}/results"

LOG_DIR="${PROJECT_DIR}/logs"

HUMANN_RESULTS_DIR="${RESULTS_DIR}/04_humann3"


#############################################################
# SHARED DATABASE ROOT
#############################################################
#
# All reference databases are stored in this shared directory.
#
# The directory is shared across users and projects.
#
#############################################################

DATABASE_DIR="/home/biox/databases"


#############################################################
# HUMAN GENOME DATABASE
#############################################################
#
# Bowtie2 index prefix used for host DNA removal.
#
# Expected files:
#
# human_GRCh38.1.bt2
# human_GRCh38.2.bt2
# human_GRCh38.3.bt2
# human_GRCh38.4.bt2
# human_GRCh38.rev.1.bt2
# human_GRCh38.rev.2.bt2
#
#############################################################

HUMAN_DB="${DATABASE_DIR}/host_human/human_GRCh38"


#############################################################
# METAPHLAN DATABASE - MG-SHOTGUN
#############################################################
#
# Used by the MG-Shotgun environment.
#
# MetaPhlAn version:
# 4.2.5
#
# Database:
# mpa_vJan26_CHOCOPhlAnSGB_202605
#
#############################################################

METAPHLAN_DB="${DATABASE_DIR}/metaphlan"


#############################################################
# METAPHLAN DATABASE - HUMANN
#############################################################
#
# Used by HUMAnN 3.9 through the MetaPhlAn version
# installed inside HUMAnN-func.
#
# MetaPhlAn version:
# 4.1.1
#
# Database:
# mpa_vJun23_CHOCOPhlAnSGB_202403
#
# IMPORTANT:
# This database is kept separate from the MetaPhlAn
# database used by MG-Shotgun.
#
#############################################################

HUMANN_METAPHLAN_DB="${DATABASE_DIR}/metaphlan_humann"


#############################################################
# HUMANN DATABASES
#############################################################

CHOCOPHLAN_DB="${DATABASE_DIR}/chocophlan/chocophlan"

UNIREF_DB="${DATABASE_DIR}/uniref/uniref"

UTILITY_DB="${DATABASE_DIR}/utility_mapping/utility_mapping"


#############################################################
# HUMANN METAPHLAN INDEX
#############################################################
#
# Index corresponding to the MetaPhlAn database used
# inside HUMAnN-func.
#
#############################################################

HUMANN_INDEX="mpa_vJun23_CHOCOPhlAnSGB_202403"