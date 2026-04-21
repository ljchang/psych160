#!/bin/bash

# Name of the job 
#SBATCH --job-name=fMRIprep_grace

# Number of compute nodes
#SBATCH --nodes=1

# Number of CPUs per task
#SBATCH --cpus-per-task=8

# Request memory
#SBATCH --mem-per-cpu=4gb

# save logs (change YOUR-DIRECTORY to where you want to save logs)
#SBATCH --output=/dartfs/rc/lab/D/DBIC/cosanlab/datax/Projects/emotion_portraits/1128_data/fmriprep_log.txt
#SBATCH --error=/dartfs/rc/lab/D/DBIC/cosanlab/datax/Projects/emotion_portraits/1128_data/fmriprep_error.txt

# Walltime (job duration)
#SBATCH --time=24:00:00

# Array jobs (* change the range according to # of subject; % = number of active job array tasks)
#SBATCH --array=1-1%1

# Email notifications (*comma-separated options: BEGIN,END,FAIL)
#SBATCH --mail-type=BEGIN,END,FAIL

# Account to use (*change to any other account you are affiliated with)
#SBATCH --account=dbic

# Parameters
participants=(01)
PARTICIPANT_LABEL=${participants[(${SLURM_ARRAY_TASK_ID} - 1)]}
BIDS_DIR=/dartfs/rc/lab/D/DBIC/DBIC/dbic-inbox/DICOM/2026/04/17/A007393/
OUTPUT_DIR=/dartfs/rc/lab/D/DBIC/cosanlab/datax/Projects/emotion_portraits/1128_data/
WORK_DIR=/dartfs/rc/lab/D/DBIC/cosanlab/datax/Projects/emotion_portraits/work/
FMRIPREP_RESOURCES_PATH=/dartfs/rc/lab/D/DBIC/DBIC/psych160/resources/fmriprep/

echo "array id: " ${SLURM_ARRAY_TASK_ID}, "subject id: " ${PARTICIPANT_LABEL}

singularity run \
                --cleanenv \
                -B ${FMRIPREP_RESOURCES_PATH}:/resources \
                -B ${BIDS_DIR}:/data \
                -B ${WORK_DIR}:/work \
                -B ${OUTPUT_DIR}:/output \
        ${FMRIPREP_RESOURCES_PATH}/fmriprep-21.0.1.simg /data /output \
        participant --participant_label $PARTICIPANT_LABEL \
        -w /work \
        --nprocs 8 \
        --write-graph \
        --fs-license-file /resources/license.txt \
        --ignore slicetiming \
        --fs-no-reconall \