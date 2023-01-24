#!/bin/bash

# This script should be called as follows (after setting all options below as needed):
# nohup bash run_sat_benchmark.sh --run path/to/benchmark-file 2>&1 > OUT &
# After executing this command, you can press Ctrl+C and later log out of the server 
# PROPERLY, i.e., with "exit" and not due to a connection timeout.
# 
# The progress can be monitored in real time with:
# tail -f OUT
# Also check with `htop` that the machine's cores are actually busy.
# 
# To stop/cancel an experiment running in the background, run:
# bash run_sat_benchmark.sh --stop
# 
# You can extract basic coverage / run time information from finished experiments like so:
# bash sat_benchmark.sh --extract path/to/my/experiment
# The provided path must contain a folder named i for each instance index i.
# In that path, some text files with raw information will be created.
# - qualified-runtimes-and-results.txt: 
#   Contains one line for each instance with its ID, the run time (= time limit if 
#   unsolved) and the found result ("sat" or "unsat" or "unknown").
# - qualified-runtimes-{sat,unsat}.txt:
#   Contains one line for each instance found {SAT, UNSAT} with its ID and the run time.
# - cdf-runtimes.txt, cdf-runtimes-{sat,unsat}.txt:
#   Using one of these files as a sequence of x- and y-coordinates, you will get a 
#   performance plot as commonly used by the SAT community. The x-coordinate is the time 
#   limit per instance and the y-coordinate is the number of instances solved in that 
#   limit.

#####################################################################
# TODO Configuration of your experiments

# Set to 1 if you want to throw out all filtered clauses from clause buffer
ccb=0
# Set to 1 if you want to set all bit of producers to 0
spo=0

#LBD experiment
#Paramters : DEFAULT, REVERSED, RANDOM, WORST
lbdm="WORST"

#Resharing
cfci=120

# 8 for normal utilization, keeping hardware threads idle
# 4 for full utilization, spawning a solver at each hardware thread
nhwthreadsperproc=8

# Some environment variables for Mallob
RDMAV_FORK_SAFE=1
NPROCS="$(($(nproc)/$nhwthreadsperproc))" 
PATH="build:$PATH"

# TODO Set the portfolio of solvers to cycle through
# (k=Kissat, c=CaDiCaL, l=Lingeling, g=Glucose)
portfolio="kkclkkclkkclkkclccgg"
#portfolio="k"
#portfolio="c"

# Clause buffering decay factor. Usually 1.0 for modestly parallel setups
# and 0.9 for massively parallel setups.
cbdf=1.0

# Timeout per instance in seconds
timeout=60

# Run all instances from this index up to the end
# (Default: 1; set to another number i if continuing an interrupted 
# experiment where i-1 instances were run successfully)
startinstance=1

# TODO Base log directory; use a descriptive name for each experiment. No spaces.
baselogdir="worst_lbd_with_no_resharing_on_instance_335"

# TODO Add any further options to the name of this log directory as well.
# Results from older experiments with the same sublogdir will be overwritten!
sublogdir="${baselogdir}/${portfolio}-cbdf${cbdf}-T${timeout}"

# TODO Define single instance file
instance="instances/instance_335.cnf"

# TODO Define verbosity
verbosity=4


# TODO Add further options to these arguments Mallob is called with.
malloboptions="-t=4 -T=$timeout -v=3 -sleep=1000 -appmode=fork -v=$verbosity -interface-fs=0 -trace-dir=. -pipe-large-solutions=0 -processes-per-host=$NPROCS -regular-process-allocation -max-lits-per-thread=50000000 -strict-clause-length-limit=20 -clause-filter-clear-interval=$cfci -max-lbd-partition-size=2 -export-chunks=20 -clause-buffer-discount=$cbdf -satsolver=$portfolio -ccb=$ccb -spo=$spo -lbdm=$lbdm"

# Cleanup / killing function
function cleanup() {
    killall -9 mpirun 2>/dev/null
    killall -9 build/mallob 2>/dev/null
    killall -9 ./build/mallob_sat_process 2>/dev/null
    rm /dev/shm/*mallob* 2>/dev/null
}

# Clean up other running experiments
if [ "$1" == "--stop" ]; then
    touch STOP_IMMEDIATELY
    cleanup
    sleep 3
    rm STOP_IMMEDIATELY
    echo "Stopped experiments."
    exit 0
fi

logdir="${sublogdir}/$i"
rm -rf $logdir 2>/dev/null
mkdir -p $logdir

mpirun -np $NPROCS --bind-to hwthread --map-by ppr:${NPROCS}:node:pe=$nhwthreadsperproc build/mallob -mono=$instance $malloboptions 2>&1 > $logdir/OUT




