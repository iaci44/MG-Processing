#!/bin/bash

#############################################################
# HUMAnN restart / fix stuck run
#############################################################

echo "======================================"
echo " Restarting stuck HUMAnN run"
echo "======================================"


#############################################################
# KILL RUNNING PROCESSES
#############################################################

echo "Searching running processes..."


P=$(ps -eo pid,cmd | grep -E "humann |bowtie2 |diamond |humann.sh |gzip -cd.*clean" | grep -v grep | awk '{print $1}')


if [ -n "$P" ]
then

    echo "Killing processes:"
    echo "$P"


    kill -CONT $P 2>/dev/null

    kill -9 $P 2>/dev/null

else

    echo "No running processes found"

fi



pkill -9 -f humann.sh 2>/dev/null



echo ""
echo "Remaining HUMAnN processes:"

pgrep -c -f humann.sh



#############################################################
# SAMPLE TO CLEAN
#############################################################

if [ -z "$1" ]

then

    echo "Usage:"
    echo "./restart_humann.sh SAMPLE_NAME"

    exit 1

fi



SAMPLE=$1


echo ""
echo "Cleaning interrupted sample: ${SAMPLE}"


rm -rf \
results/04_humann3/per_sample/${SAMPLE}/${SAMPLE}_humann_temp*


rm -f \
results/04_humann3/per_sample/${SAMPLE}/${SAMPLE}_concat.fastq.gz



#############################################################
# RELAUNCH HUMANN
#############################################################

echo ""
echo "Restarting HUMAnN..."


nohup bash scripts/humann.sh \
> logs/humann.log 2>&1 &


echo $! > logs/humann.pid


echo "Restart submitted"