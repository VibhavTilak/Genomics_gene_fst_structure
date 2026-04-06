# 1D SFS for each population - validate shape before 3D
#PLEASE RUN THIS IN THE DIRECTORY WHERE THE .saf.idx FILES ARE STORED. FEEL FREE TO CHANGE THE NUMBER OF THREADS MENTIONED BY THE FLAG "-P 20"

realSFS abuensis.saf.idx -P 20 > abuensis.1d.sfs
realSFS albogularis.saf.idx -P 20 > albogularis.1d.sfs
realSFS hyperythra.saf.idx -P 20 > hyperythra.1d.sfs
