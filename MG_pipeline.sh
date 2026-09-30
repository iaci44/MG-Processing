#!/bin/bash

#############################################################
# Shotgun Metagenomics Pipeline
#############################################################

set -e


#############################################################
# LOAD CONFIGURATION
#############################################################

source config/config.sh

#############################################################
# CHECK DATABASES
#############################################################

if [ ! -f "${HUMAN_DB}.1.bt2" ] && [ ! -f "${HUMAN_DB}.1.bt2l" ]

then

echo "ERROR: Human Bowtie2 database not found:"
echo "${HUMAN_DB}"

exit 1

fi
#############################################################
# CREATE REQUIRED DIRECTORIES
#############################################################

mkdir -p \
${PROJECT_DIR}/metadata \
${PROJECT_DIR}/results/01_qc \
${PROJECT_DIR}/results/02_host_removed \
${PROJECT_DIR}/results/03_metaphlan \
${PROJECT_DIR}/results/04_humann3 \
${PROJECT_DIR}/logs


#############################################################
# GLOBAL LOGGING
#############################################################

exec > >(tee -i ${LOG_DIR}/pipeline.log)
exec 2>&1



echo "======================================"
echo " Shotgun Metagenomics Pipeline"
echo "======================================"



#############################################################
# LIST SAMPLES
#############################################################

echo "Creating sample list..."


cd ${PROJECT_DIR}


ls raw_fastq/*_R1.fastq.gz \
| sed 's|.*/||; s|_R1.fastq.gz||' \
> metadata/samples.txt



echo "Number of samples:"
wc -l metadata/samples.txt


echo "Samples detected:"
cat metadata/samples.txt



#############################################################
# STEP 1 - QUALITY CONTROL
#############################################################

echo "======================================"
echo "STEP 1 - QUALITY CONTROL"
echo "======================================"


conda activate MG-Shotgun



fastqc \
-t ${THREADS} \
-o ${PROJECT_DIR}/results/01_qc \
${PROJECT_DIR}/raw_fastq/*.fastq.gz



echo "FastQC completed"



#############################################################
# OPTIONAL TRIMMING WITH FASTP
#############################################################

RUN_TRIMMING=false


if [ "$RUN_TRIMMING" = true ]

then

echo "Running fastp trimming"



while read S

do


fastp \
-i ${PROJECT_DIR}/raw_fastq/${S}_R1.fastq.gz \
-I ${PROJECT_DIR}/raw_fastq/${S}_R2.fastq.gz \
-o ${PROJECT_DIR}/results/01_qc/${S}_trim_R1.fastq.gz \
-O ${PROJECT_DIR}/results/01_qc/${S}_trim_R2.fastq.gz \
--detect_adapter_for_pe \
--qualified_quality_phred 20 \
--length_required 20 \
--thread ${THREADS} \
-h ${PROJECT_DIR}/results/01_qc/${S}_fastp.html



done < ${PROJECT_DIR}/metadata/samples.txt



else

echo "Trimming skipped"



fi




#############################################################
# STEP 2 - REMOVE HOST READS
#############################################################

echo "======================================"
echo "STEP 2 - HOST READ REMOVAL"
echo "======================================"


conda activate MG-Shotgun


while read S

do


if [ -s ${PROJECT_DIR}/results/02_host_removed/${S}_clean_R1.fastq.gz ]

then

echo "Skipping ${S}: host removal already completed"

continue

fi



echo "Removing host reads: ${S}"



bowtie2 \
-x ${HUMAN_DB} \
-1 ${PROJECT_DIR}/raw_fastq/${S}_R1.fastq.gz \
-2 ${PROJECT_DIR}/raw_fastq/${S}_R2.fastq.gz \
-p ${THREADS} \
--very-sensitive \
--un-conc-gz ${PROJECT_DIR}/results/02_host_removed/${S}_clean_R%.fastq.gz \
-S /dev/null \
2> ${PROJECT_DIR}/logs/${S}_host.log



done < ${PROJECT_DIR}/metadata/samples.txt



echo "Host removal completed"





#############################################################
# STEP 3 - TAXONOMIC PROFILING (MetaPhlAn)
#############################################################

echo "======================================"
echo "STEP 3 - METAPHLAN TAXONOMIC PROFILE"
echo "======================================"


conda activate MG-Shotgun



while read S

do


if [ -s ${PROJECT_DIR}/results/03_metaphlan/${S}_profile.tsv ]

then

echo "Skipping ${S}: MetaPhlAn already completed"

continue

fi



echo "Running MetaPhlAn: ${S}"



metaphlan \
${PROJECT_DIR}/results/02_host_removed/${S}_clean_R1.fastq.gz,${PROJECT_DIR}/results/02_host_removed/${S}_clean_R2.fastq.gz \
--input_type fastq \
--bowtie2db ${METAPHLAN_DB} \
--bowtie2out ${PROJECT_DIR}/results/03_metaphlan/${S}_bt2.bz2 \
--nproc ${THREADS} \
-t rel_ab_w_read_stats \
-o ${PROJECT_DIR}/results/03_metaphlan/${S}_profile.tsv



done < ${PROJECT_DIR}/metadata/samples.txt





#############################################################
# MERGE METAPHLAN RESULTS
#############################################################

echo "Merging MetaPhlAn profiles..."



merge_metaphlan_tables.py \
${PROJECT_DIR}/results/03_metaphlan/*_profile.tsv \
> ${PROJECT_DIR}/results/03_metaphlan/merged_abundance_table.tsv



echo "MetaPhlAn completed"





#############################################################
# STEP 4 - FUNCTIONAL PROFILING (HUMAnN)
#############################################################

echo "======================================"
echo "STEP 4 - HUMAnN FUNCTIONAL PROFILE"
echo "======================================"


conda activate HUMAnN-func



IN=${PROJECT_DIR}/results/02_host_removed

OUT=${PROJECT_DIR}/results/04_humann3



mkdir -p ${OUT}/per_sample
mkdir -p ${OUT}/logs





SORTED=$(while read S; do


FILE=${IN}/${S}_clean_R1.fastq.gz


if [ -f "$FILE" ]

then

echo "$(du -k $FILE | cut -f1) $S"

fi


done < ${PROJECT_DIR}/metadata/samples.txt \
| sort -n \
| awk '{print $2}')





for S in ${SORTED}


do



SAMPLE_OUT=${OUT}/per_sample/${S}



if ls ${SAMPLE_OUT}/*_genefamilies.tsv 1>/dev/null 2>&1

then

echo "Skipping ${S}: HUMAnN already completed"

continue

fi



mkdir -p ${SAMPLE_OUT}



echo "Running HUMAnN: ${S}"




cat <(zcat ${IN}/${S}_clean_R1.fastq.gz) \
<(zcat ${IN}/${S}_clean_R2.fastq.gz) \
| gzip > ${SAMPLE_OUT}/${S}_concat.fastq.gz





humann \
--input ${SAMPLE_OUT}/${S}_concat.fastq.gz \
--output ${SAMPLE_OUT} \
--output-basename ${S} \
--threads ${THREADS} \
--memory-use minimum \
--metaphlan-options "--bowtie2db ${METAPHLAN_DB} --index ${HUMANN_INDEX} --nproc ${THREADS}" \
--remove-temp-output \
--o-log ${OUT}/logs/${S}.log





rm -f ${SAMPLE_OUT}/${S}_concat.fastq.gz



done



echo "HUMAnN completed"



echo "======================================"
echo " PIPELINE FINISHED"
echo "======================================"