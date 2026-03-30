#!/usr/bin/env bash
set -euo pipefail

# RAGTAG PATH (EXPLICIT)
RAGTAG_BIN="/home/biogeography/miniconda3/envs/ragtag/bin/ragtag.py"

# THREADS
THREADS=8

# INPUT FASTA FILES (note that u have to clean the header of fastq files
TGUT_FASTA="/mnt/d/vibhav/pyjo/04_Zfpyjoalign/tgut.clean.fa"  	#GUIDE GENOME (ZF normally)
PYJO_FASTA="/mnt/d/vibhav/pyjo/04_Zfpyjoalign/pyjo.clean.fa"	#QUERY GENOME 

# FILTER SMALL SCAFFOLDS, dw u wont miss out on genes 
MINLEN=50000
PYJO_FILTERED="/mnt/d/vibhav/pyjo/04_Zfpyjoalign/pyjo.filtered.fa"

# OUTPUT DIRECTORY
OUTDIR="/mnt/d/vibhav/pyjo/05_ragtag_pyjo"
mkdir -p "${OUTDIR}"

LOG="${OUTDIR}/ragtag.log"
exec > >(tee -i "${LOG}") 2>&1


echo "RagTag scaffolding: PyJo → T. guttata"
echo "Started: $(date)"


# STEP 1: FILTER PYJO SCAFFOLDS
echo "[STEP 1] Filtering PyJo scaffolds >= ${MINLEN} bp"
seqkit seq -m ${MINLEN} "${PYJO_FASTA}" > "${PYJO_FILTERED}"

# STEP 2: RUNNING RAGTAG
echo "[STEP 2] Running RagTag scaffold (8 threads)"

"${RAGTAG_BIN}" scaffold \
  "${TGUT_FASTA}" \
  "${PYJO_FILTERED}" \
  -t "${THREADS}" \
  -o "${OUTDIR}"
  
# FINISH
echo "RagTag done broooo"
echo "Finished: $(date)"
echo
echo "Key outputs:"
echo "  Pseudochromosomes : ${OUTDIR}/ragtag.scaffold.fasta"
echo "  AGP file          : ${OUTDIR}/ragtag.scaffold.agp"
echo "  Unplaced contigs  : ${OUTDIR}/ragtag.unplaced.fasta"
echo "  Confidence report : ${OUTDIR}/ragtag.confidence.txt"
echo "  Log               : ${LOG}"

