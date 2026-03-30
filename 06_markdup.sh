#!/usr/bin/env bash
set -euo pipefail

# TOOL, no need for Picard again.. just use samtools and fixmate!
SAMTOOLS_BIN="/usr/local/bin/samtools"

# THREADS
THREADS=20

# INPUT
BAM_DIR="/home/birdlab/Desktop/vibhav/tawny/04_mapping_sorted"

# OUTPUT
OUTDIR="/home/birdlab/Desktop/vibhav/tawny/05_dedup_bam"
TMPDIR="/home/birdlab/Desktop/vibhav/tawny/05_dedup_bam/tmp"
mkdir -p "${OUTDIR}" "${TMPDIR}"

LOG="${OUTDIR}/mark_duplicates.log"
exec > >(tee -i "${LOG}") 2>&1


echo "Marking PCR duplicates (samtools fixmate + markdup)"
echo "Started: $(date)"


# LOOP OVER SORTED BAMS

for BAM in "${BAM_DIR}"/*.sorted.bam; do

    SAMPLE=$(basename "${BAM}" .sorted.bam)

    echo "Processing sample: ${SAMPLE}"
	
    # 1. NAME-SORT
    "${SAMTOOLS_BIN}" sort -n -@ "${THREADS}" \
        -o "${TMPDIR}/${SAMPLE}.namesorted.bam" \
        "${BAM}"
		
    # 2. FIX MATES
    "${SAMTOOLS_BIN}" fixmate -m \
        "${TMPDIR}/${SAMPLE}.namesorted.bam" \
        "${TMPDIR}/${SAMPLE}.fixmate.bam"

    # 3. COORDINATE SORT
    "${SAMTOOLS_BIN}" sort -@ "${THREADS}" \
        -o "${TMPDIR}/${SAMPLE}.coordsorted.bam" \
        "${TMPDIR}/${SAMPLE}.fixmate.bam"
		
    # 4. MARK DUPLICATES
    "${SAMTOOLS_BIN}" markdup -@ "${THREADS}" \
        "${TMPDIR}/${SAMPLE}.coordsorted.bam" \
        "${OUTDIR}/${SAMPLE}.dedup.bam"
		
    # 5. INDEX
    "${SAMTOOLS_BIN}" index \
        "${OUTDIR}/${SAMPLE}.dedup.bam"
		
    # CLEAN TEMP FILES
    rm -f \
        "${TMPDIR}/${SAMPLE}.namesorted.bam" \
        "${TMPDIR}/${SAMPLE}.fixmate.bam" \
        "${TMPDIR}/${SAMPLE}.coordsorted.bam"

done

# FINISH
echo "Duplicate marking finished correctly!"
echo "Finished: $(date)"
echo
echo "Outputs:"
echo "  ${OUTDIR}/*.dedup.bam"
echo "  ${OUTDIR}/*.bai"
echo "  Log: ${LOG}"
echo "	DONE WITH MARKING DUPLICATES BROO"

