#!/usr/bin/env bash
set -euo pipefail

# TOOL PATHS, DONT USE PICARD, I DONT LIKE PICARD, USE SAMTOOLS + FIXMATE TO DO THIS, (GUY LEONARD'S ADEVENTURES IN GENOMICS TUTORIAL)
BWA_BIN="/home/birdlab/softs/bwa/bwa"
SAMTOOLS_BIN="/usr/local/bin/samtools"
#PICARD_BIN="/home/birdlab/softs/picard.jar"   

# INPUT
REF="/home/birdlab/Desktop/Vibhav/tawny/02_reference/mixornis_gularis/GCA_055770555.1_ASM5577055v1_genomic.fna"

# LOG
LOG="/home/birdlab/Desktop/Vibhav/tawny/03_indexing/indexing.log"
exec > >(tee -i "${LOG}") 2>&1

echo "Indexing"
echo "Started: $(date)"

# BWA INDEX
echo "[STEP 1] BWA index"
"${BWA_BIN}" index "${REF}"

# SAMTOOLS FASTA INDEX
echo "[STEP 2] samtools faidx"
"${SAMTOOLS_BIN}" faidx "${REF}"

# PICARD DICTIONARY

#echo "[STEP 3] Picard CreateSequenceDictionary"
#"${PICARD_BIN}" CreateSequenceDictionary \
#  R="${REF}" \
#  O="${REF%.fasta}.dict"
  
  #samtools dict /mnt/d/vibhav/pyjo/03_mapping/GCA_013400435.1_ASM1340043v1_genomic.fna \
   # > /mnt/d/vibhav/pyjo/03_mapping/GCA_013400435.1_ASM1340043v1_genomic.dict

 #samtools dict /mnt/d/vibhav/pyjo/03_mapping/GCA_013400435.1_ASM1340043v1_genomic.fna \
  #  > /mnt/d/vibhav/pyjo/03_mapping/GCA_013400435.1_ASM1340043v1_genomic.dict

# FINISH
echo "Indexing finished successfully!"
echo "Finished: $(date)"
echo
echo "Generated files:"
echo "  ${REF}.bwt (and related BWA index files)"
echo "  ${REF}.fai"
echo "  ${REF%.fasta}.dict"
echo " DONE WITH INDEXING "
