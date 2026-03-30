#!/usr/bin/env bash
set -euo pipefail

# TOOL PATHS
BWA_BIN="/home/birdlab/softs/bwa/bwa"
SAMTOOLS_BIN="/usr/local/bin/samtools"

# THREADS
THREADS=20

# INPUTS
REF="/home/birdlab/Desktop/vibhav/tawny/02_reference/mixornis_gularis/GCA_055770555.1_ASM5577055v1_genomic.fna" 	# Reference genome 
FASTQ_DIR="/home/birdlab/Desktop/vibhav/tawny/01_trimmed"				# Trimmed FASTQ directory

# OUTPUT
OUTDIR="/home/birdlab/Desktop/vibhav/tawny/04_mapping_sorted"
mkdir -p "${OUTDIR}"

LOG="${OUTDIR}/mapping_sorting.log"
exec > >(tee -i "${LOG}") 2>&1

echo "Mapping + sorting reads (paired-end only)"
echo "Started: $(date)"

# LOOP OVER SAMPLES (PAIRED READS ONLY)
shopt -s nullglob

for R1 in "${FASTQ_DIR}"/*_1.trim.fastq.gz; do

    SAMPLE=$(basename "${R1}" | sed 's/_1.trim.fastq.gz//')

    R1_FILE="${FASTQ_DIR}/${SAMPLE}_1.trim.fastq.gz"
    R2_FILE="${FASTQ_DIR}/${SAMPLE}_2.trim.fastq.gz"

    # Sanity check
    if [[ ! -f "${R1_FILE}" || ! -f "${R2_FILE}" ]]; then
        echo "ERROR: Paired FASTQ files missing for sample ${SAMPLE}"
        echo "R1: ${R1_FILE}"
        echo "R2: ${R2_FILE}"
        exit 1
    fi

    echo "Processing sample: ${SAMPLE}"

    # MAP + SORT
    "${BWA_BIN}" mem -t "${THREADS}" "${REF}" \
        "${R1_FILE}" "${R2_FILE}" \
    | "${SAMTOOLS_BIN}" sort -@ "${THREADS}" \
        -o "${OUTDIR}/${SAMPLE}.sorted.bam"

    # INDEX BAM
    "${SAMTOOLS_BIN}" index "${OUTDIR}/${SAMPLE}.sorted.bam"

done

# FINISH
echo "Mapping + sorting finished BROOOOOOO"
echo "Finished: $(date)"
echo
echo "Outputs:"
echo "  ${OUTDIR}/*.sorted.bam"
echo "  ${OUTDIR}/*.bai"
echo "  Log: ${LOG}"
echo "	bro done broo mapping and sortinggggg done broo"
