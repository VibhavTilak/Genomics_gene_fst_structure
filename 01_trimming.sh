#!/bin/bash

softpath=/home/bird_biochemist/soft/Trimmomatic-0.39/ #Path to software directory
inpath=/mnt/d/vibhav/00_raw/LTS/ #Path to input raw files directory
outpath=/mnt/d/vibhav/01_trimmed/ #Path to output trimmed files directory
trimpath=/mnt/d/vibhav/01_trimmed/trimlog #Path to trimlog summary directory
#email=tilak_20221152@students.iisertirupati.ac.in   # Your email address for notifications

mkdir -p $outpath # Create output directory if it doesn't exist

#echo "Starting trimming at $(date)" | mail -s "Trimming Started" $email

for i in $inpath*_R1_001.fastq.gz; do
	file=$(basename $i _R1_001.fastq.gz);
	echo $file;
	/usr/bin/java -jar $softpath"trimmomatic-0.39.jar" PE \
		-phred33 -threads 10 -summary $trimpath$file".txt" \
		$inpath$file"_R1_001.fastq.gz" $inpath$file"_R2_001.fastq.gz" \
		$outpath$file"_R1_paired.fastq.gz" $outpath$file"_R1_unpaired.fastq.gz" \
		$outpath$file"_R2_paired.fastq.gz" $outpath$file"_R2_unpaired.fastq.gz" \
		ILLUMINACLIP:$softpath"adapters/TruSeq3-PE.fa":2:30:10:2:True LEADING:3 TRAILING:3 MINLEN:36;
	done

#echo "Trimming completed at $(date)" | mail -s "Trimming Finished" $email
