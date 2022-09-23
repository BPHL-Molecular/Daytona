#!/bin/bash -ue
samplename=$(echo /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758 | rev | cut -d "/" -f 1 | rev)
#singularity exec /apps/staphb-toolkit/containers/bwa_0.7.17.sif bwa mem /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/reference/nCoV-2019.reference.fasta /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/${samplename}_1.fq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/${samplename}_2.fq.gz | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools view - -F 4 -u -h | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort > /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.sorted.bam

singularity exec /apps/staphb-toolkit/containers/bwa_0.7.17.sif bwa mem /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/reference/nCoV-2019.reference.fasta /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/${samplename}_1.fq.gz /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/${samplename}_2.fq.gz | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools view - -F 4 -u -h | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort -n > /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.namesorted.bam
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools fixmate -m /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.namesorted.bam /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.fixmate.bam
    #Create positional sorted bam from fixmate.bam
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort -o /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.positionsort.bam /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.fixmate.bam
    #Mark duplicate reads
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools markdup /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.positionsort.bam /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.markdup.bam
    #Remove duplicate reads
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools markdup -r /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.positionsort.bam /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.dedup.bam
    #Sort dedup.bam and rename to .sorted.bam
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort -o /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.sorted.bam /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.dedup.bam
   #Index final sorted bam
#singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools index /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.sorted.bam
