#!/bin/bash
#SBATCH --job-name=river_detect
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=100G
#SBATCH --time=24:00:00
#SBATCH --mail-type=all
#SBATCH --mail-user=rc5007@princeton.edu

date

cd /home/rc5007/River_detection/MatlabRiverDetectionCode
module purge
module load matlab/R2022a

matlab -nodisplay -noFigureWindows -nosplash < run_batch_river_detection.m

date
