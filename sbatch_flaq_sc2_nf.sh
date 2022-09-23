#!/bin/bash
#SBATCH --account=bphl-umbrella
#SBATCH --qos=bphl-umbrella
#SBATCH --job-name=flaq_sc2_nf
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=15
#SBATCH --mem=100gb
#SBATCH --output=flaq_sc2_nf.%j.out
#SBATCH --error=flaq_sc2_nf.%j.err

#Run script/command and use $SLURM_CPUS_ON_NODE
module load singularity

nextflow run flaq_sc2_humanclean2.nf -params-file params.yaml

sort ./output/*/report.txt | uniq > ./output/sum_report.txt
sed -i '/sampleID\treference/d' ./output/sum_report.txt
sed -i '1i sampleID\treference\tstart\tend\tnum_raw_reads\tnum_clean_reads\tnum_mapped_reads\tpercent_mapped_clean_reads\tcov_bases_mapped\tpercent_genome_cov_map\tmean_depth\tmean_base_qual\tmean_map_qual\tassembly_length\tnumN\tpercent_ref_genome_cov\tVADR_flag\tQC_flag\tpangolin_version\tlineage\tSOTC' ./output/sum_report.txt

cat ./output/assemblies/*.fa > ./output/assemblies.fasta
singularity exec /apps/staphb-toolkit/containers/nextclade_2021-03-15.sif nextclade --input-fasta ./output/assemblies.fasta --output-csv ./output/nextclade_report.csv
