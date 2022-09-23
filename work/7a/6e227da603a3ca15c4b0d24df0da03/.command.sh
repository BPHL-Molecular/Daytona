#!/bin/bash -ue
#echo /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/fastqs/XJMV22000758_1.fastq.gz >> xfile.txt

mkdir -p /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/assemblies
mkdir -p /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/variants
mkdir -p /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/vadr_error_reports
mkdir -p /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758
cp /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/fastqs/XJMV22000758_*.fastq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758

#Run fastqc on original reads
singularity exec --cleanenv /apps/staphb-toolkit/containers/fastqc_0.11.9.sif fastqc /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1.fastq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2.fastq.gz
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_fastqc.html /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_original_fastqc.html
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_fastqc.zip /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_original_fastqc.zip
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_fastqc.html /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_original_fastqc.html
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_fastqc.zip /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_original_fastqc.zip

# Run sra-human-scrubber to remove human reads
gzip -d /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1.fastq.gz
gzip -d /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2.fastq.gz
singularity exec -B /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758:/data /apps/staphb-toolkit/containers/sra-human-scrubber_1.1.2021-05-05.sif /opt/scrubber/scripts/scrub.sh -r -i /data/XJMV22000758_1.fastq -o /data/XJMV22000758_1_humanclean.fastq
singularity exec -B /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758:/data /apps/staphb-toolkit/containers/sra-human-scrubber_1.1.2021-05-05.sif /opt/scrubber/scripts/scrub.sh -r -i /data/XJMV22000758_2.fastq -o /data/XJMV22000758_2_humanclean.fastq
gzip /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_humanclean.fastq
gzip /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_humanclean.fastq

#Run trimmomatic
singularity exec --cleanenv /apps/staphb-toolkit/containers/trimmomatic_0.39.sif trimmomatic PE -phred33 -trimlog /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758.log /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_humanclean.fastq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_humanclean.fastq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_trim_1.fastq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_unpaired_trim_1.fastq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_trim_2.fastq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_unpaired_trim_2.fastq.gz SLIDINGWINDOW:4:30 MINLEN:75 TRAILING:20 > /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_trimstats.txt
rm /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_unpaired_trim_*.fastq.gz
rm /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1.fastq /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2.fastq

#Run bbduk to remove Illumina adapter sequences and any PhiX contamination  
singularity exec --cleanenv /apps/staphb-toolkit/containers/bbtools_38.76.sif bbduk.sh in1=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_trim_1.fastq.gz in2=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_trim_2.fastq.gz out1=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1.rmadpt.fq.gz out2=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2.rmadpt.fq.gz ref=/bbmap/resources/adapters.fa stats=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758.adapters.stats.txt ktrim=r k=23 mink=11 hdist=1 tpe tbo
singularity exec --cleanenv /apps/staphb-toolkit/containers/bbtools_38.76.sif bbduk.sh in1=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1.rmadpt.fq.gz in2=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2.rmadpt.fq.gz out1=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1.fq.gz out2=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2.fq.gz outm=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_matchedphix.fq ref=/bbmap/resources/phix174_ill.ref.fa.gz k=31 hdist=1 stats=/blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_phixstats.txt
rm /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_trim*.fastq.gz
rm /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758*rmadpt.fq.gz

#Run fastqc on clean forward and reverse reads
singularity exec --cleanenv /apps/staphb-toolkit/containers/fastqc_0.11.9.sif fastqc /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1.fq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2.fq.gz
#Rename fastqc output files
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_fastqc.html /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_clean_fastqc.html
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_fastqc.zip /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_1_clean_fastqc.zip
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_fastqc.html /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_clean_fastqc.html
mv /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_fastqc.zip /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_2_clean_fastqc.zip

#Run multiqc
singularity exec --cleanenv /apps/staphb-toolkit/containers/multiqc_1.8.sif multiqc /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/XJMV22000758_*_fastqc.zip -o /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758

#Map reads to reference
mkdir /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment
