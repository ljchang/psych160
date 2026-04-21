# Thank you Eunhye Choe for sharing all these files!
# make a directory if needed
mkdir /dartfs-hpc/rc/lab/T/TseP/Eunhye/resources/heudiconv

# load docker and build a singularity image
singularity pull /dartfs-hpc/rc/lab/T/TseP/Eunhye/resources/heudiconv/heudiconv_latest.sif docker://nipreps/heudiconv:latest

# generate a script
cd ~/Documents/fMRI/scripts
nano dicom_to_bids.sh

# generate a python script for dbic data
nano reproin.py

# run
srun dicom_to_bids.sh