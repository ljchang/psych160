# Thank you Eunhye Choe for sharing all these files!
#!/bin/bash
#SBATCH --job-name=dicom_to_bids
#SBATCH --output=slurm-%j.out
#SBATCH --time=04:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4

DICOM_DIR=~/Documents/fMRI/rawMR
BIDS_DIR=~/Documents/fMRI/bids
SCRIPTS_DIR=~/Documents/fMRI/scripts

singularity run \
    --cleanenv \
    -B $DICOM_DIR:/data:ro \
    -B $BIDS_DIR:/output \
    -B $SCRIPTS_DIR:/scripts \
    docker://nipy/heudiconv:latest \
    -d /data/*/*.dcm \
    -s A007393 \
    -f /scripts/reproin.py \
    -c dcm2niix \
    -b \
    --overwrite \
    -o /output