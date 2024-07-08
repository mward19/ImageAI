#!/bin/bash --login

  

#SBATCH --time=8:00:00 # walltime

#SBATCH --ntasks=1 # number of processor cores (i.e. tasks)

#SBATCH --nodes=1 # number of nodes

#SBATCH --gpus=4

#SBATCH --mail-user=ejl62@byu.edu # email address

#SBATCH --mail-type=END

#SBATCH --export=NONE

#SBATCH --mem 60G

  

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.

export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE

export PATH=/apps/spack/root/opt/spack/linux-rhel9-haswell/gcc-13.2.0/cuda-12.4.1-pw6cogp5nuczn2qcgqnw6lvqdznny2ef/bin:${PATH}
export LD_LIBRARY_PATH=/apps/spack/root/opt/spack/linux-rhel9-haswell/gcc-13.2.0/cuda-12.4.1-pw6cogp5nuczn2qcgqnw6lvqdznny2ef/lib64:${LD_LIBRARY_PATH}
  

# LOAD MODULES, INSERT CODE, AND RUN YOUR PROGRAMS HERE

  

module load miniconda3/24.3.0-poykqmt
module load cuda/12.4.1-pw6cogp

source activate pytom

  
pytom_match_template.py \
 -t /home/ejl62/ImageAI/template-matching/PyTom/tm_tutorial/templates/80S.mrc \
 -m /home/ejl62/ImageAI/template-matching/PyTom/tm_tutorial/templates/mask.mrc \
 -v /home/ejl62/fsl_groups/fslg_imagseg/nobackup/archive/template_matching/pytom_tutorial/dataset/tomo200528_100.mrc \
 -d /home/ejl62/fsl_groups/fslg_imagseg/nobackup/archive/template_matching/pytom_tutorial/results_80S/ \
 --particle-diameter 300 \
 -a /home/ejl62/fsl_groups/fslg_imagseg/nobackup/archive/template_matching/pytom_tutorial/dataset/tomo200528_100.rawtlt \
 --low-pass 40 \
 --defocus 3 \
 --amplitude 0.08 \
 --spherical 2.7 \
 --voltage 200 \
 --tomogram-ctf-model phase-flip \
 -g 0