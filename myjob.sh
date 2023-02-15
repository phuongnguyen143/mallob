#!/bin/bash
SBATCH --nodes=1
SBATCH --ntasks-per-node=12
SBATCH --cpus-per-task=8
SBATCH --ntasks-per-core=2 # enables hyperthreading
SBATCH -t 00:02:00 # 2 minutes
SBATCH -p general # general or micro 
SBATCH --account=di93jox # TODO fill in your account ID
SBATCH -J FirstJob # TODO fill in your name for the job
SBATCH --ear=off # disable Energy-Aware Runtime for accurate performance
SBATCH --ear-mpi-dist=openmpi # If using OpenMPI and EAR is not disabled

# SuperMUC has TWO processors with 24 physical cores each, 
# totalling 48 physical cores (96 hwthreads). See: 
# https://doku.lrz.de/download/attachments/43321076/SuperMUC-NG_computenode.png

# Load the same modules to compile Mallob
module load slurm_setup
module unload devEnv/Intel/2019 intel-mpi
module load gcc/9 intel-mpi/2019-gcc cmake/3.14.5 gdb

# Some output for debugging
module list
which mpirun
echo "#ranks: $SLURM_NTASKS"

# Use the HOME directory for logging. This is a comparably slow file system.
logdir=logs/job_$SLURM_JOB_ID
# If available, use the WORK directory for logging.
# TODO Replace YOURPROJECTNAME.
WORK_YOURPROJECTNAME=FirstJob
if [ -d $WORK_YOURPROJECTNAME ]; then logdir="$WORK_YOURPROJECTNAME/$logdir"; fi

# Configure the run time options of Mallob. This is just an example.
# TODO Add your own options, set -T according to the time limit given above.
taskspernode=12 # must be same as --ntasks-per-node above
cmd="build/mallob -q -T=60 -mono=instances/r3unsat_300.cnf -t=4 -log=$logdir -v=4 -rpa=1 -pph=$taskspernode"

# Create the logging directory and its subdirectories. This way it is much faster
# than if all ranks attempt to do it at the same time when launching Mallob.
mkdir -p "$logdir"
oldpath=$(pwd)
cd "$logdir"
for rank in $(seq 0 $(($SLURM_NTASKS-1))); do
        mkdir $rank
done
cd "$oldpath"

# Environment variables for the job
export PATH="build/:$PATH"
export RDMAV_FORK_SAFE=1

echo JOB_LAUNCHING
echo "$cmd"
srun -n $SLURM_NTASKS $cmd
echo JOB_FINISHED