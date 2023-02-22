#!/bin/bash
#SBATCH --nodes=17
#SBATCH --ntasks-per-node=12
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-core=2 # enables hyperthreading
#SBATCH -t 00:35:00 # 35 minutes
#SBATCH -p general # general or micro 
#SBATCH --account=pn72pu
#SBATCH -J testrun
#SBATCH --ear=off # disable Energy-Aware Runtime for accurate performance
# SBATCH --ear-mpi-dist=openmpi # If using OpenMPI and EAR is not disabled

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
WORK_YOURPROJECTNAME="testrun"
if [ -d $WORK_YOURPROJECTNAME ]; then logdir="$WORK_YOURPROJECTNAME/$logdir"; fi


# -------------------------------CONFIGURE SCHEDULING PARAMETERS------------------------------
taskspernode=12 # must be same as --ntasks-per-node above
jwl=300
numInstances=400
scheduleparameter="-c=1 -ajpc=1 -job-desc-template=../benchmarks.txt -job-template=templates/job-template.json --client-template=templates/client-template.json -J=$numInstances -jwl=$jwl -pls=0"

# -------------------------------SET UP MALLOB OPTIONS--------------------------------------
# 8 for normal utilization, keeping hardware threads idle
# 4 for full utilization, spawning a solver at each hardware thread
nhwthreadsperproc=8

# Some environment variables for Mallob
NPROCS="$(($(nproc)/$nhwthreadsperproc))" 
# (k=Kissat, c=CaDiCaL, l=Lingeling, g=Glucose)
portfolio="kkclkkclkkclkkclccgg"
#portfolio="k"
#portfolio="c"

# Clause buffering decay factor. Usually 1.0 for modestly parallel setups
# and 0.9 for massively parallel setups.
cbdf=1.0

# Timeout per instance in seconds
timeout=300

# Run all instances from this index up to the end
# (Default: 1; set to another number i if continuing an interrupted 
# experiment where i-1 instances were run successfully)
startinstance=1

# TODO Configuration of your experiments

# Set to 1 if you want to throw out all filtered clauses from clause buffer
ccb=0
# Set to 1 if you want to set all bit of producers to 0
spo=0

#LBD experiment
#Paramters : DEFAULT, REVERSED, RANDOM, WORST
lbdm="DEFAULT"

#Resharing
cfci=500

malloboptions="-t=4 -T=$timeout -v=3 -sleep=1000 -appmode=fork -v=3 -interface-fs=0 -trace-dir=. -processes-per-host=$NPROCS -regular-process-allocation -max-lits-per-thread=50000000 -strict-clause-length-limit=20 -clause-filter-clear-interval=$cfci -max-lbd-partition-size=2 -export-chunks=20 -clause-buffer-discount=$cbdf -satsolver=$portfolio -ccb=$ccb -spo=$spo -lbdm=$lbdm"


cmd="build/mallob -q $scheduleparameter -log=$logdir -rpa=1 -pph=$taskspernode $malloboptions"

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