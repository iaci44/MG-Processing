#!/bin/bash

#############################################################
# HUMAnN monitoring script
#############################################################

echo "======================================"
echo " HUMAnN / Pipeline monitoring"
echo "======================================"


#############################################################
# CHECK RUNNING PROCESSES
#############################################################

echo ""
echo "Number of running HUMAnN processes:"

pgrep -c -f humann



#############################################################
# SHOW LOG PROGRESS
#############################################################

echo ""
echo "Last lines of pipeline log:"

tail -20 logs/pipeline.log



#############################################################
# COUNT COMPLETED SAMPLES
#############################################################

echo ""
echo "Completed HUMAnN samples:"


ls results/04_humann3/per_sample/*/*_genefamilies.tsv 2>/dev/null | wc -l



#############################################################
# CHECK IF PIPELINE IS STILL RUNNING
#############################################################

echo ""
echo "Pipeline status:"


if [ -f logs/pipeline.pid ]

then

    if ps -p $(cat logs/pipeline.pid) > /dev/null

    then
        echo "Pipeline is still running"

    else
        echo "Pipeline stopped"

    fi


else

    echo "PID file not found"

fi