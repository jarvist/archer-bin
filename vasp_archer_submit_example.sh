#!/bin/bash --login

#PBS -N VSP
#PBS -l select=4
#PBS -l walltime=00:05:00
#PBS -A e05-gener-wal

# Note: select = No. Nodes (24 CPUS per node)
# Also from the architecture the sweet spots should be:
# 4 nodes (96 cores), which is one blade
#
# and multiples of four up to
#
# 64 nodes (1536 cores), which is one chassis.


export OMP_NUM_THREADS=1
ulimit -s unlimited
module load vasp5/5.3.3

export NPROC=`qstat -f $PBS_JOBID | awk '/Resource_List.mpiprocs/ {print $3}'`

cd $PBS_O_WORKDIR

aprun -n $NPROC vasp5 > vasp.out

