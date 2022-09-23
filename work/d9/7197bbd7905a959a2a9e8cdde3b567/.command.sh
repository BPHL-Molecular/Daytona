#!/bin/bash -ue
samplename=$(echo /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758 | rev | cut -d "/" -f 1 | rev)
#Call variants
mkdir /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/variants
samtools mpileup -A -d 8000 --reference /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/reference/nCoV-2019.reference.fasta -B -Q 0 /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.primertrim.sorted.bam | ivar variants -r /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/reference/nCoV-2019.reference.fasta -m 10 -p /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/variants/${samplename}.variants -q 20 -t 0.25 -g /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/reference/GCF_009858895.2_ASM985889v3_genomic.gff

#Generate consensus assembly
mkdir /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/assembly
samtools mpileup -A -B -d 8000 --reference /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/reference/nCoV-2019.reference.fasta -Q 0 /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/alignment/${samplename}.primertrim.sorted.bam | ivar consensus -t 0 -m 10 -n N -p /blue/bphl-florida/dongyibo/Dev_flaq_sc2_nf/output/XJMV22000758/assembly/${samplename}.consensus
