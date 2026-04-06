#!/usr/bin/env bash
set -euo pipefail

OUTDIR="/media/birdlab/bird_hdd_13/Vibhav/tawny/10_selection"
INDIR="/media/birdlab/bird_hdd_13/Vibhav/tawny/09_pairwise_fst"

mkdir -p "${OUTDIR}"

echo "started $(date)"

for POP in hyperythra albogularis abuensis; do
    echo "Processing ${POP}"

    # Step 1: SAF + SFS → theta
    realSFS saf2theta \
        "${INDIR}/${POP}.saf.idx" \
        -sfs "${INDIR}/${POP}.1d.sfs" \
        -outname "${OUTDIR}/${POP}" \
        -fold 1 \
        -P 20

    # Step 2: per-site theta output
    thetaStat print \
        "${OUTDIR}/${POP}.thetas.idx" \
        > "${OUTDIR}/${POP}.persite.txt"

done

echo "All populations processed successfully! $(date)"





