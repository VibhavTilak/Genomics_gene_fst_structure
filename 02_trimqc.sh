#!/usr/bin/env bash
set -euo pipefail


# Directory containing trimmed FASTQ files
TRIMMED_FASTQ_DIR="/mnt/d/vibhav/pyjo/02_trimming/trimmed"

# Output directories
FASTQC_OUT="/mnt/d/vibhav/pyjo/02_trimming/trimmed"
MULTIQC_OUT="/mnt/d/vibhav/pyjo/02_trimming/trimmed"

# Number of threads
THREADS=8

mkdir -p "${FASTQC_OUT}"
mkdir -p "${MULTIQC_OUT}"

echo "Chill Vibhav FastQC running on trimmed FASTQ files"
echo "Input:  ${TRIMMED_FASTQ_DIR}"
echo "Output: ${FASTQC_OUT}"
echo "Threads: ${THREADS}"

fastqc \
  -t "${THREADS}" \
  -o "${FASTQC_OUT}" \
  "${TRIMMED_FASTQ_DIR}"/*.fastq.gz

echo "Brooo finally completed FastQC successfully."


#RUN THIS IFF THERE IS HUGE SAMPLE SET! 
# ==============================
# RUN MULTIQC
# ==============================

#echo "Running MultiQC..."

#multiqc \
#  "${FASTQC_OUT}" \
#  -o "${MULTIQC_OUT}"

#echo "MultiQC completed successfully."

#echo "===================================="
#echo "QC finished!"
#echo "MultiQC report:"
#echo "${MULTIQC_OUT}/multiqc_report.html"
#echo "===================================="
