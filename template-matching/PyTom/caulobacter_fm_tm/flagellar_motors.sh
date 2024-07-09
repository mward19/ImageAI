#!/bin/bash --login




#SBATCH --time=2:00:00 # walltime

#SBATCH --ntasks=1 # number of processor cores (i.e. tasks)

#SBATCH --nodes=1 # number of nodes

#SBATCH --gpus=2

#SBATCH --mail-user=ejl62@byu.edu # email address

#SBATCH --mail-type=END

#SBATCH --export=NONE

#SBATCH --mem 10G

  

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.

export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE
export PATH=/apps/spack/root/opt/spack/linux-rhel9-haswell/gcc-13.2.0/cuda-12.4.1-pw6cogp5nuczn2qcgqnw6lvqdznny2ef/bin:${PATH}
export LD_LIBRARY_PATH=/apps/spack/root/opt/spack/linux-rhel9-haswell/gcc-13.2.0/cuda-12.4.1-pw6cogp5nuczn2qcgqnw6lvqdznny2ef/lib64:${LD_LIBRARY_PATH} 

# LOAD MODULES, INSERT CODE, AND RUN YOUR PROGRAMS HERE 

module load miniconda3/24.3.0-poykqmt
module load cuda/12.4.1-pw6cogp

source activate pytom

pytom_create_template.py \
 -i /home/ejl62/fsl_groups/fslg_imagseg/nobackup/archive/eben/template_matching/fm_caulo_tm/flagellum_AvgVol_4P120.mrc \
 -o /home/ejl62/template_matching_shared/pytom/flagellar_motor_tm/templates_masks/caulobacter_fm_template.mrc \
 --input-voxel 13.33 \
 --output-voxel 14.08 \
 --center

pytom_create_mask.py \
 -b 200 \
 -o /home/ejl62/template_matching_shared/pytom/flagellar_motor_tm/templates_masks/caulobacter_fm_mask.mrc \
 --voxel-size 14.08 \
 --radius 110 \
 --sigma 1
  
pytom_match_template.py \
 -t /home/ejl62/template_matching_shared/pytom/flagellar_motor_tm/templates_masks/caulobacter_fm_template.mrc \
 -m /home/ejl62/template_matching_shared/pytom/flagellar_motor_tm/templates_masks/caulobacter_fm_mask.mrc \
 -v /home/ejl62/fsl_groups/grp_tomo_db1_d1/nobackup/archive/TomoDB1_d1/FlagellarMotor_P1/Caulobacter\ crescentus/flag_3_full.rec \
 -d /home/ejl62/template_matching_shared/pytom/flagellar_motor_tm/results \
 --particle-diameter 300 \
 --tilt-angles -55 55 \
 --random-phase \
 -g CUDA_VISIBLE_DEVICES