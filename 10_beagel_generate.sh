#!/usr/bin/env bash
set -euo pipefail

# ALL POPULATIONS BEAGLE
# Using genotype likelihoods (correct for 5× LC genomes)
# ALL POPULATIONS BEAGLE  BEAGLE WILL GIVE ME LIKLIEHOODS, AT 5X I THOUGHT RATHER THAN HARD GENOTYPING BY VCFS, BEAGLE WLD BE FINE.
# All 18 individuals together
# Order: hyperythra (7) albogularis (7) abuensis (4)
# This order MUST match sample info in R
REF="/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/GCA_055770555.1_ASM5577055v1_genomic.fna"
BAMLIST="/media/birdlab/bird_hdd_13/Vibhav/tawny/all_samples.txt"
OUTDIR="/media/birdlab/bird_hdd_13/Vibhav/tawny/08_structure"

mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

THREADS=20

echo "Using bamlist: ${BAMLIST}"
echo "Total individuals: $(wc -l < ${BAMLIST})"

# BEAGLE — all 18 together
# doGlf 2 ensures beagle format for PCAngsd
# minMaf 0.05 remove very rare variants which might be sequencing errrors at 5x ?? 
# No SNP_pvalue restrictions.... too strict for 5x LC
# minInd 12 75% of 18 total individuals
# Major/minor called consistently across
# all individuals simultaneously — required
# for valid PCA/admixture comparisons
echo "Beagle — all 18 individuals"
echo "Started: $(date)"

angsd \
  -GL 1 \
  -doGlf 2 \
  -doMajorMinor 1 \
  -doMaf 1 \
  -minMaf 0.05 \
  -minInd 13 \
  -minMapQ 20 \
  -minQ 20 \
  -setMinDepthInd 2 \
  -skipTriallelic 1 \
  -uniqueOnly 1 \
  -remove_bads 1 \
  -only_proper_pairs 1 \
  -C 50 \
  -baq 2 \
  -nThreads ${THREADS} \
  -bam ${BAMLIST} \
  -ref "${REF}" \
  -out all_pops

echo "Total SNPs in beagle: $(zcat all_pops.beagle.gz | tail -n +2 | wc -l)"
echo "DONE: $(date)"
echo "Output: ${OUTDIR}/all_pops.beagle.gz"
