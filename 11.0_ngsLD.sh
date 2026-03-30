#!/usr/bin/env bash
set -euo pipefail



# INPUTS
BEAGLE="/media/birdlab/bird_hdd_13/Vibhav/tawny/08_structure/all_pops.beagle.gz"
OUTDIR="/media/birdlab/bird_hdd_13/Vibhav/tawny/08_structure"
OUTPREFIX="all_pops"
THREADS=20
N_IND=18
mkdir -p "${OUTDIR}"
cd "${OUTDIR}"



#THIN SNPs (keep every 10th) 
# Reduces 2.7M → ~270k SNPs so ngsLD pairwise comparisons stay manageable.
# (NR-1)%10==0 keeps rows 2,12,22... i.e. first data SNP always included
echo "Thinning SNPs (10%)..."
zcat "${BEAGLE}" \
  | awk 'NR==1 || (NR-1)%10==0' \
  | gzip > "${OUTPREFIX}.thinned.beagle.gz"


# ngsLD needs chr<TAB>pos
# BEAGLE marker IDs are chr_pos → split on underscore
echo "Creating positions file..."
zcat "${OUTPREFIX}.thinned.beagle.gz" \
  | tail -n +2 \
  | cut -f1 \
  | awk -F'_' '{print $1"\t"$2}' > "${OUTPREFIX}.thinned.positions.txt"



# COUNT SNPs 
NSITES=$(zcat "${OUTPREFIX}.thinned.beagle.gz" | tail -n +2 | wc -l)
echo "Thinned SNPs: ${NSITES}"



# ngsLD 
# --probs        : input is genotype likelihoods (BEAGLE), not hard genotypes
# --max_kb_dist  : only compute LD within 100kb (adjust to your species LD decay)
# --min_maf 0.05 : skip low-MAF pairs — GLs are noisy at 5x, inflates LD
# --rnd_sample   : compute 1% of pairs; sufficient for pruning at ~270k SNPs
# Output cols    : pos1 pos2 dist r² D D' r²_prime
echo "Running ngsLD..."
echo "Started: $(date)"
ngsLD \
  --geno "${OUTPREFIX}.thinned.beagle.gz" \
  --probs \
  --pos "${OUTPREFIX}.thinned.positions.txt" \
  --n_ind ${N_IND} \
  --n_sites ${NSITES} \
  --out "${OUTPREFIX}.ngsld" \
  --max_kb_dist 100 \
  --min_maf 0.05 \
  --rnd_sample 0.01 \
  --n_threads ${THREADS}
echo "ngsLD done: $(date)"



# GRAPH-BASED LD PRUNING
# --header        : ngsLD output has a header row
# --weight "r2"   : use r² column (col 7) — confirmed from head -1
# --filter        : drop edges where r² > 0.3
echo "Pruning SNPs with prune_graph..."
~/softs/prune_graph/target/release/prune_graph \
  --in "${OUTPREFIX}.ngsld" \
  --header \
  --weight "r2" \
  --filter "r2 > 0.3" \
  --out "${OUTPREFIX}.keep.snps" \
  -n ${THREADS}

echo "SNPs to keep after pruning: $(wc -l < "${OUTPREFIX}.keep.snps")"



# CHECK ID FORMAT COMPATIBILITY
# prune_ngsLD.py outputs SNP IDs as chr:pos (colon) but BEAGLE uses chr_pos (underscore)
# Check and convert if needed so the awk lookup in Step 7 works correctly
SAMPLE_KEEP=$(head -1 "${OUTPREFIX}.keep.snps")
SAMPLE_BEAGLE=$(zcat "${OUTPREFIX}.thinned.beagle.gz" | awk 'NR==2 {print $1}')
if [[ "${SAMPLE_KEEP}" == *":"* ]] && [[ "${SAMPLE_BEAGLE}" == *"_"* ]]; then
  echo "Converting keep.snps IDs from chr:pos → chr_pos to match BEAGLE format..."
  sed 's/:/\_/' "${OUTPREFIX}.keep.snps" > "${OUTPREFIX}.keep.snps.fmt"
else
  cp "${OUTPREFIX}.keep.snps" "${OUTPREFIX}.keep.snps.fmt"
fi



# FILTER THINNED BEAGLE
# Filter the THINNED beagle — keep.snps only contains thinned SNP IDs
# Filtering the original 2.7M BEAGLE would silently drop all non-thinned SNPs
echo "Filtering thinned Beagle to pruned SNP set..."
zcat "${OUTPREFIX}.thinned.beagle.gz" | \
  awk 'NR==FNR {keep[$1]; next} NR==1 || ($1 in keep)' \
  "${OUTPREFIX}.keep.snps.fmt" - | \
  gzip > "${OUTPREFIX}.pruned.beagle.gz"

# FINAL COUNTS 
echo "---"
echo "Original SNPs (full BEAGLE):  $(zcat "${BEAGLE}" | tail -n +2 | wc -l)"
echo "After thinning (10%):         $(zcat "${OUTPREFIX}.thinned.beagle.gz" | tail -n +2 | wc -l)"
echo "After LD pruning:             $(zcat "${OUTPREFIX}.pruned.beagle.gz" | tail -n +2 | wc -l)"
echo "---"
echo "Pipeline complete: $(date)"
echo "Final output: ${OUTDIR}/${OUTPREFIX}.pruned.beagle.gz"
