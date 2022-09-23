#!/bin/bash -ue
samplename=$(echo /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758 | rev | cut -d "/" -f 1 | rev)
#Index final sorted bam
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools index /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.sorted.bam

#Trim primers with iVar
ivar trim -i /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.sorted.bam  -b /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/primers/ARTIC-V4.1.bed -p /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.primertrim -e
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.primertrim.bam -o /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.primertrim.sorted.bam
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools index /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.primertrim.sorted.bam
singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools coverage /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.primertrim.sorted.bam -o /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.coverage.txt
