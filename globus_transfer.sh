#!/bin/bash

# Load the Globus Command-Line Interface module
module load globus-cli

# Define source and destination endpoints
export SourceShare=cba0b848-09a1-11eb-8933-0a5521ff3f4b 
export DestinationShare=fd35d66e-09a0-11eb-8933-0a5521ff3f4b

# Define source and destination paths
export SourcePath=
export DestinationPath=

# Read input arguments
if [[ "$#" != 2 ]]
then
	echo "Illegal number of input parameters." >&2
	exit 1
fi

export FREQUENCY=$1
export PREV_TASK_ID=$2

if [[ $PREV_TASK_ID != "NA" ]]
then
	# Check for existing transfer job
	STATUS=`globus task show $PREV_TASK_ID | grep -oP '^Status:\s*\K[A-Z]*'`
	echo "STATUS = $STATUS"
	# If previous transfer did not succeed, error and exit
	if [[ $STATUS != "SUCCEEDED" ]]
	then
		echo "ERROR: Previous transfer not completed successfully.  Please check Globus transfer status." >&2
		exit 1
	fi
fi

# If previous transfer succeeded, start new transfer and then submit next job
transfer_command="globus transfer $SourceShare:$SourcePath $DestinationShare:$DestinationPath --recursive --sync-level checksum"
PREV_TASK_ID=`$transfer_command | grep -oP '^Task ID:\s*\K[A-Za-z0-9-]*'`
export PREV_TASK_ID
$transfer_command
echo $PREV_TASK_ID

job_submit="sbatch --export=PREV_TASK_ID=${PREV_TASK_ID} --begin=now+${FREQUENCY}days globus_transfer.submit"
$job_submit
echo $job_submit
echo ""
echo ""
echo ""
