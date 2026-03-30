#!/usr/bin/env bash
set -euo pipefail


# HYPERYTHRA SAF (n=7)
REF="/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/GCA_055770555.1_ASM5577055v1_genomic.fna"
BAMLIST="/media/birdlab/bird_hdd_13/Vibhav/tawny/hyperythra_bamlist.txt"
OUTDIR="/media/birdlab/bird_hdd_13/Vibhav/tawny/07_pairwise_fst"
mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

THREADS=8
MININD=5    # 75% of 7


# SAF
# GL 1         = SAMtools model, better for 5x LC than GATK
# doSaf 1      = compute site allele frequency likelihoods
# doMajorMinor = infer major/minor from GLs
# doMaf        = estimate allele frequencies from GLs
# baq 2        = extended BAQ, aggressive indel correction for LC
# setMinDepthInd 2 = at least 2 reads per individual at a site
# skipTriallelic   = at 5x these are sequencing errors not real variants
# No -minMaf, no -SNP_pval — these bias the SFS
echo "SAF — hyperythra"
echo "Started: $(date)"


angsd \
  -GL 1 \
  -doSaf 1 \
  -doMajorMinor 1 \
  -doMaf 1 \
  -minInd ${MININD} \
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
  -bam "${BAMLIST}" \
  -ref "${REF}" \
  -anc "${REF}" \
  -out hyperythra

echo "hyperythra SAF sites: $(zcat hyperythra.saf.pos.gz | wc -l)"
echo "DONE: $(date)"
echo "Outputs: hyperythra.saf.idx hyperythra.saf.pos.gz hyperythra.mafs.gz"
