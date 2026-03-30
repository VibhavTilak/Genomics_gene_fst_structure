#!/usr/bin/env bash
set -euo pipefail

THREADS=20

# Zebra finch — source (chromosome level, gene annotations)
ZF_FASTA="/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/GCF_048771995.1_bTaeGut7.mat_genomic.fna"
ZF_GFF="/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/tae_gut.gff"

# Mixornis — target (scaffold level, no annotations)
MX_FASTA="/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/GCA_055770555.1_ASM5577055v1_genomic.fna"

# Output
OUTDIR="/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis"
PAF_FILE="${OUTDIR}/zf_to_mixornis.paf"
GENE_BED="${OUTDIR}/mixornis_genes.bed"
UNMAPPED="${OUTDIR}/unmapped_genes.txt"

# ─── STEP 1: WHOLE GENOME ALIGNMENT ───────────────────────────────────────────
# minimap2 -x asm5 : preset for cross-species alignment ~5% divergence
#                    appropriate for bird-to-bird (~10-15% divergence is fine too)
# Target = Mixornis (query coordinates get mapped INTO target space)
# Query  = Zebra finch (source of gene annotations)
# --cs removed — not needed, we only use PAF coordinates not cigar strings
# -c    : output CIGAR in PAF (needed for accurate coordinate projection)
# Note  : PAF cols used downstream:
#         [0]=q_name [2]=q_start [3]=q_end [4]=strand
#         [5]=t_name [7]=t_start [8]=t_end [11]=mapq
echo "======================================"
echo "STEP 1: Whole genome alignment ZF → Mixornis"
echo "Started: $(date)"
echo "======================================"

minimap2 \
  -x asm5 \
  -t ${THREADS} \
  ${MX_FASTA} \
  ${ZF_FASTA} \
  > ${PAF_FILE} \
  2> ${OUTDIR}/minimap2.log

echo "Alignment done: $(date)"
echo "PAF lines: $(wc -l < ${PAF_FILE})"

# ─── STEP 2: MAP GENE COORDINATES ─────────────────────────────────────────────
echo "======================================"
echo "STEP 2: Mapping gene coordinates"
echo "======================================"

python3 << 'PYEOF'
import re
import sys

PAF_FILE   = "/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/zf_to_mixornis.paf"
GFF_FILE   = "/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/tae_gut.gff"
OUT_FILE   = "/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/mixornis_genes.bed"
UNMAP_FILE = "/media/birdlab/bird_hdd_13/Vibhav/tawny/02_reference/mixornis_gularis/unmapped_genes.txt"
MAPQ_THRESH   = 10    # minimum mapping quality — removes ambiguous alignments
OVERLAP_FRAC  = 0.5   # minimum fraction of gene that must overlap an alignment block

# ── Load PAF alignments ────────────────────────────────────────────────────────
# Also record target scaffold lengths (col 6) for coordinate clamping
print("Loading PAF alignments...")
aln_index    = {}   # query_scaffold → list of alignments
target_sizes = {}   # target_scaffold → length

with open(PAF_FILE) as f:
    for line in f:
        fields = line.strip().split('\t')
        if len(fields) < 12:
            continue
        mapq = int(fields[11])
        if mapq < MAPQ_THRESH:
            continue
        t_name = fields[5]
        t_len  = int(fields[6])
        aln = {
            'q_name':  fields[0],
            'q_len':   int(fields[1]),
            'q_start': int(fields[2]),
            'q_end':   int(fields[3]),
            'strand':  fields[4],
            't_name':  t_name,
            't_len':   t_len,
            't_start': int(fields[7]),
            't_end':   int(fields[8]),
            'mapq':    mapq
        }
        target_sizes[t_name] = t_len
        aln_index.setdefault(aln['q_name'], []).append(aln)

print(f"Scaffolds with alignments: {len(aln_index)}")

# ── Helper: extract gene name from GFF attributes ─────────────────────────────
# NCBI GFFs can use Name=, gene=, or locus_tag= — check all three in priority order
def get_gene_name(attrs):
    for tag in ['Name=', 'gene=', 'locus_tag=']:
        m = re.search(r'(?<=' + re.escape(tag) + r')[^;]+', attrs)
        if m:
            return m.group(0)
    return "unknown"

# ── Map gene coordinates ───────────────────────────────────────────────────────
print("Mapping gene coordinates...")
mapped   = 0
unmapped = 0

with open(GFF_FILE) as gff, \
     open(OUT_FILE,   'w') as out, \
     open(UNMAP_FILE, 'w') as unmap:

    out.write("chr\tstart\tend\tgene\tstrand\n")

    for line in gff:
        if line.startswith('#'):
            continue
        fields = line.strip().split('\t')
        if len(fields) < 9 or fields[2] != 'gene':
            continue

        zf_chr   = fields[0]
        zf_start = int(fields[3]) - 1  # GFF is 1-based → convert to 0-based BED
        zf_end   = int(fields[4])       # GFF end is inclusive, BED end is exclusive — no change needed
        gene_len = zf_end - zf_start
        gene     = get_gene_name(fields[8])

        # No alignments for this scaffold at all
        if zf_chr not in aln_index:
            unmapped += 1
            unmap.write(f"{gene}\t{zf_chr}\t{zf_start}\t{zf_end}\tno_alignment\n")
            continue

        # Find the alignment block with the best overlap with this gene
        best_aln     = None
        best_overlap = 0

        for aln in aln_index[zf_chr]:
            overlap = min(zf_end, aln['q_end']) - max(zf_start, aln['q_start'])
            if overlap > best_overlap:
                best_overlap = overlap
                best_aln = aln

        # Require at least OVERLAP_FRAC of the gene to fall within the alignment block
        if best_aln is None or best_overlap < gene_len * OVERLAP_FRAC:
            unmapped += 1
            unmap.write(f"{gene}\t{zf_chr}\t{zf_start}\t{zf_end}\tlow_overlap\n")
            continue

        # ── Coordinate projection ──────────────────────────────────────────────
        # offset = distance of gene start from the start of the alignment block
        # in query (ZF) space
        offset = zf_start - best_aln['q_start']

        if best_aln['strand'] == '+':
            # Forward alignment: query start maps to target start
            mx_start = best_aln['t_start'] + offset
            mx_end   = mx_start + gene_len
            out_strand = '+'
        else:
            # Reverse alignment: query start maps to target END (strand is flipped)
            # The further into the query we are (larger offset), the further
            # from target end we are → subtract offset from t_end
            mx_end   = best_aln['t_end'] - offset
            mx_start = mx_end - gene_len
            out_strand = '-'

        # Clamp to valid scaffold coordinates
        t_len    = best_aln['t_len']
        mx_start = max(0, min(mx_start, t_len))
        mx_end   = max(0, min(mx_end,   t_len))

        if mx_start >= mx_end:
            unmapped += 1
            unmap.write(f"{gene}\t{zf_chr}\t{zf_start}\t{zf_end}\tinvalid_coords\n")
            continue

        out.write(f"{best_aln['t_name']}\t{mx_start}\t{mx_end}\t{gene}\t{out_strand}\n")
        mapped += 1

total = mapped + unmapped
print(f"\n======================================")
print(f"Mapped:        {mapped}")
print(f"Unmapped:      {unmapped}")
print(f"Success rate:  {mapped/total*100:.1f}%")
print(f"Output BED:    {OUT_FILE}")
print(f"Unmapped list: {UNMAP_FILE}")
print(f"======================================")
PYEOF

# ─── STEP 3: SANITY CHECKS ────────────────────────────────────────────────────
echo "======================================"
echo "STEP 3: Sanity checks"
echo "======================================"

echo "Total genes mapped: $(tail -n +2 ${GENE_BED} | wc -l)"
echo "Unique scaffolds:   $(tail -n +2 ${GENE_BED} | cut -f1 | sort -u | wc -l)"
echo "Unmapped genes:     $(wc -l < ${UNMAPPED})"
echo ""
echo "First 5 mapped genes:"
head -6 ${GENE_BED}

echo "======================================"
echo "DONE: $(date)"
echo ""
echo "Outputs:"
echo "  ${PAF_FILE}  ← whole genome alignment"
echo "  ${GENE_BED}  ← gene coords in Mixornis space"
echo "  ${UNMAPPED}  ← genes that failed to map"
echo "======================================"
