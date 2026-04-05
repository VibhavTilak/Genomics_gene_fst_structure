# Genomics_gene_fst_structure

In this directory, I aim to do population structure, per gene pair wise fst for subspecies. With my 5x LC data, and at a later stage dadi analysis to date the splits at which the subspecies formed (appeared)
Follow the pipeline as per the numbers sequentially.

------------------------------------------------------------------------------------------------------------------------------------------------------------

**POINTS TO NOTE:**
01_trimming.sh and 02_triqc.sh are must to run scripts.

03 script uses ragtag to align the short scaffold level reads of a reference to the long chromosome level reads of zebra finch. So use it in case of a pseudochromosome analysis. You can skip oherwise to 04.0. 

Incase the gene annotations are important part of analysis and you dont have a .gff or .gtf or a .gbbf file without any attributes, run 04.1 script. It aligns your reference genome to zebra finch using MINIMAP and lifts over the coordinates from Zebra finch genome to your reference genome.

Run the scripts from 05 to 07 compulsory regardless of the analysis.
                                              
I would prefer running 10_beagle_generate.sh if working with LC 5x data. The resuslts are same regardless of using vcf or beagle, but I wld prefer beagle as it preserves the genotype likliehoods rather than hard genotyping which can be erroneous at 5X.

As for 09_pairwise_fst.sh, use whichfst -1, which is the flag for hudsons fst which takes into account the sample size bias and gives you a corrected fst value and later when you get a pair wise per site fst, using Bhatia et al correction, calculate it for per gene. The R script rcode_manhattan_fstoutlier.R takes care of this and gives you nice plots. 
