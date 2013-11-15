#!/bin/sh

#Automagic .com CX1 (Imperial College London HPC) job submitter. A WIP. 
#JMF 2007-09
#Bash is a stranger in an open car...
#2012-04-27: Finally got around to adding single CPU defaults (for quick semi-empirical QC)

#2012-05-26: Forking this code to use for running NWCHEM .nw programs
#2012-06: Now runs multi-host over MPI for NWCHEM
#2012-06-18: Extended to restart NWCHEM jobs. Also, I actually learnt how to use 'getopts' as part of this.

#2013-11-14: Very initial VASP / Archer version - lots still hardcoded. Wraps
#up 4x input files into the shell via redirects. Assumed I'd have to do this to
#run in the temporary file space, but Archer seems to default to dropping you
#directly into your work folder (where the job is submitted from) so not
#necessary. How do TMP files work here? Mmm.
# Aha hah - ARCHER doesn't have any tmp directory, as the compute nodes have no disks...

# RUN AS ./executable.sh OTHERWISE OPTIONS WILL NOT BE GATHERED!

#Get Options

#Generalising this script to different machines for generality.

HOST=` hostname `
# wmd-master --> NEON
# aquila-0   --> AQUILA
# eslogin004 --> ARCHER

case "${HOST}" in
	wmd-master ) 
		echo "Hello Neon!"
		BUNDLE=0
		ACCOUNT= ;;
	aquila* )
		echo "Hello Aquila!"
		BUNDLE=0
		ACCOUNT= ;;
	eslogin* )
		echo "Hello Archer!"	
		ACCOUNT=e05-gener-wal ;;
	*)
		echo "I don't think we've met ${HOST}. Might be problems!"
esac

NCPUS=24
MEM=11800mb   #Simon Burbidge correction - lots of nodes with 12GB physical memory, leaves no overhead for OS
QUEUE="" #default route
TIME="23:58:02" # Two minutes to midnight :^)
HOSTS=1 #Ah, the Host!
RESTART="NAH"
BUNDLE=0 # Wrap up VASP INPUT files into Shell script? Doesn't work on small buffer qsub / msubs!

function USAGE()
{
 cat << EOF
Jarv's VASP file runner.

USAGE: ./launch_vasp.sh [-nmqtsl] VASP_DIRECTORIES(S)

OPTIONS:
	-n number of cpus
	-m amount of memory
	-q queue
	-t time
    -h hosts
    -s short queue (-n 1 -m 1899mb -t 0:59:59)
    -l long  queue (-n 1 -m 1899mb -t 21:58:00)

DEFAULTS (+ inspect for formatting):
	NCPUS = ${NCPUS}
	MEM   = ${MEM}
	QUEUE = ${QUEUE}
	TIME = ${TIME}
EOF
}

while getopts ":n:m:q:t:h:slr?" Option
do
    case $Option in
#OPTIONS
        n    )  NCPUS=$OPTARG;;
        m    )  MEM=$OPTARG;;
	    q    )  QUEUE=$OPTARG;;
	    t    )  TIME="${OPTARG}";;
        h    )  HOSTS="${OPTARG}";;
#FLAGS
        s    )  NCPUS=1
                TIME="0:59:59"
                MEM="1899mb";;
        l    )  NCPUS=1
                TIME="21:58:00"
                MEM="1899mb";;
        r    )  RESTART="YEAH";;
        ?    )  USAGE
                exit 0;;
        *    )  echo ""
                echo "Unimplemented option chosen."
                USAGE   # DEFAULT
    esac
done

#OK, now we should have our options
cat <<EOF
Well, here's what I understood / defaulted to:
    HOSTS   =  ${HOSTS}
    NCPUS   =  ${NCPUS}
    MEM     =  ${MEM}
    QUEUE   =  ${QUEUE}
    TIME    =  ${TIME}
    RESTART =  ${RESTART}
    BUNDLE  =  ${BUNDLE}
    ACCOUNT =  ${ACCOUNT}
EOF


shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non option item supplied on the command line
#+ if one exists.

PWD=` pwd `

for COM in $*
do
 cd "${COM}"
 FULLPATH=` pwd `
 echo $FULLPATH

 JOBFIL="${FULLPATH##*/}_RUN.sh" #Might want to change this in future, so made a variable
 echo JOBFIL "${JOBFIL}"

 cat  > ${JOBFIL} << EOF
#!/bin/bash --login
#PBS -l walltime=${TIME}
#PBS -l select=${HOSTS} 
#:ncpus=${NCPUS}:mem=${MEM}
#PBS -A ${ACCOUNT}

export OMP_NUM_THREADS=1
ulimit -s unlimited

module load vasp5/5.3.3

export PBS_O_WORKDIR=\$(readlink -f \$PBS_O_WORKDIR)

cd "\${PBS_O_WORKDIR}" #Escaped to be interpreted by the subshell running job

EOF

if (( BUNDLE ))
then

 for VASPFIL in INCAR POSCAR KPOINTS POTCAR
 do
  echo >> ${JOBFIL}
  echo "cat > ${VASPFIL} << EOFd16cfc822b4325e67e7a0695518f0242" >> ${JOBFIL} #Random md5sum to assure (statistically!) likely uniqueness in long files
  cat ${VASPFIL} >> ${JOBFIL}
  echo "EOFd16cfc822b4325e67e7a0695518f0242" >> ${JOBFIL}
 done 
fi

#OK, RUN AND CLEANUP TIME

cat  >> ${JOBFIL} << EOF


# THUNDERBIRDS ARE GO!

aprun -n '$NCPUS' vasp5 > vasp.out

#VASP vomits files everywhere, so lets bundle them up into a folder
#mkdir "${JOBFIL%.*}_out"
#mv *.* "${JOBFIL%.*}_out"
#cp -a "${JOBFIL%.*}_out" ${PWD}/${WD}/ 

echo "For us, there is only the trying. The rest is not our business. ~T.S.Eliot"

EOF

 echo "CAPTURED QSUB COMMAND: "
 cat ${JOBFIL}
# qsub -q "${QUEUE}" ${COM%.*}.sh
 cd -
done
