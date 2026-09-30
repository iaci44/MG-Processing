#!/bin/bash

#############################################################
# HUMAnN results merging
#############################################################


set -e


echo "======================================"
echo " HUMAnN RESULTS MERGING"
echo "======================================"


#############################################################
# CONFIGURATION
#############################################################

conda activate HUMAnN-func

#############################################################
# PROJECT NAME
#############################################################

if [ -z "$1" ]

then

echo "Error: project name missing"
echo "Usage: bash merge_results.sh PROJECT_NAME"

exit 1

fi


PROJECT_NAME=$1

PROJECT_DIR=${HOME}/${PROJECT_NAME}
HUMANN_DIR=${PROJECT_DIR}/results/04_humann3


cd ${HUMANN_DIR}



#############################################################
# CREATE MERGE FOLDERS
#############################################################

echo "Creating folders..."


mkdir -p merged
mkdir -p gf
mkdir -p pa
mkdir -p pc



#############################################################
# COLLECT FILES
#############################################################

echo "Collecting HUMAnN outputs..."


cp per_sample/*/*_genefamilies.tsv gf/


cp per_sample/*/*_pathabundance.tsv pa/


cp per_sample/*/*_pathcoverage.tsv pc/



#############################################################
# JOIN TABLES
#############################################################

echo "Joining gene families..."


humann_join_tables \
-i gf \
-o merged/genefamilies.tsv



echo "Joining pathway abundance..."


humann_join_tables \
-i pa \
-o merged/pathabundance.tsv



echo "Joining pathway coverage..."


humann_join_tables \
-i pc \
-o merged/pathcoverage.tsv



#############################################################
# NORMALIZATION CPM
#############################################################

echo "Normalizing tables to CPM..."


humann_renorm_table \
-i merged/genefamilies.tsv \
-o merged/genefamilies_cpm.tsv \
--units cpm



humann_renorm_table \
-i merged/pathabundance.tsv \
-o merged/pathabundance_cpm.tsv \
--units cpm



#############################################################
# SPLIT STRATIFIED TABLES
#############################################################

echo "Splitting stratified tables..."


humann_split_stratified_table \
-i merged/genefamilies_cpm.tsv \
-o merged



humann_split_stratified_table \
-i merged/pathabundance_cpm.tsv \
-o merged



echo "======================================"
echo " MERGE COMPLETED"
echo "======================================"