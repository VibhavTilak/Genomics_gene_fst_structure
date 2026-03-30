#!/usr/bin/env bash
set -uo pipefail


# PATHS
INPATH="/home/birdlab/Desktop/vibhav/tawny/05_dedup_bam"
OUTPATH="/home/birdlab/Desktop/vibhav/tawny/06_qualimap_bamqc"
mkdir -p "${OUTPATH}"


# SETTINGS
QUALIMAP_THREADS=10
PARALLEL_JOBS=2
JAVA_MEM="8G"


# FUNCTION: run BAMQC
run_bamqc() {
    bam_file="$1"
    sample=$(basename "${bam_file}" .dedup.bam)
    sample_outdir="${OUTPATH}/${sample}_bamqc"

    
    echo "Running Qualimap BAMQC for: ${sample}"
    echo "Time: $(date)"
    

    if [[ ! -f "${bam_file}" ]]; then
        echo "ERROR: BAM file not found: ${bam_file}"
        return 1
    fi

    mkdir -p "${sample_outdir}"

    # --java-mem-size MUST use = sign (no space) — confirmed from wrapper script
    qualimap bamqc \
        --java-mem-size=${JAVA_MEM} \
        -bam "${bam_file}" \
        -outdir "${sample_outdir}" \
        -outfile "${sample}.pdf" \
        -nt "${QUALIMAP_THREADS}"

    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        echo "ERROR: Qualimap failed for ${sample} (exit code: ${exit_code})"
        return ${exit_code}
    fi

    echo "Finished BAMQC for ${sample} at $(date)"
}

export -f run_bamqc
export OUTPATH QUALIMAP_THREADS JAVA_MEM


# RUN IN PARALLEL
echo "Starting Qualimap BAMQC at: $(date)"
echo "Input:  ${INPATH}"
echo "Output: ${OUTPATH}"
echo "Jobs:   ${PARALLEL_JOBS} parallel | ${QUALIMAP_THREADS} threads each | ${JAVA_MEM} RAM each"


find "${INPATH}" -name "*.dedup.bam" | \
    parallel \
        --env run_bamqc \
        --env OUTPATH \
        --env QUALIMAP_THREADS \
        --env JAVA_MEM \
        -j "${PARALLEL_JOBS}" \
        --halt never \
        --joblog "${OUTPATH}/parallel_joblog.txt" \
        run_bamqc {}



# FINISH
echo "Qualimap BAMQC finished for all samples"
echo "Finished at: $(date)"
echo "Outputs in:  ${OUTPATH}"
echo "Job log:     ${OUTPATH}/parallel_joblog.txt"
echo ""
echo "Any failed jobs (exit code != 0):"
awk 'NR>1 && $7 != 0 {print "FAILED:", $0}' "${OUTPATH}/parallel_joblog.txt" || echo "  None — all jobs completed successfully!"
