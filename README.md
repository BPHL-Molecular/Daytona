<h1 align="center">Daytona</h1>

## What to do
The pipeline is a Nextflow version of the Flaq_flaq_sc2 pipeline (FL BPHL's SARS-CoV-2 analysis pipeline). And the function of human read removal is added to the pipeline. 

## Prerequisites
The below docker container images are needed in the pipeline. These images should be downloaded to the directory /apps/staphb-toolkit/containers/ in your local computer. You can find them from ncbi/sra-human-scrubber (https://hub.docker.com/r/ncbi/sra-human-scrubber) and StaPH-B/docker-builds (https://github.com/StaPH-B/docker-builds).
1. fastqc_0.11.9.sif
2. trimmomatic_0.39.sif
3. bbtools_38.76.sif
4. multiqc_1.8.sif
5. bwa_0.7.17.sif
6. samtools_1.12.sif
7. vadr_1.3.sif
8. pangolin_4.1.2-pdata-1.13.sif
9. nextclade_2021-03-15.sif
10. sra-human-scrubber_1.1.2021-05-05.sif

## How to run
1. put your data files into directory /fastqs. Your data file's name should look like "JBS22002292_1.fastq.gz", "JBS22002292_2.fastq.gz" 
2. open file "parames.yaml", set the parameters. 
3. get into the directory of the pipeline, run "sbatch ./sbatch_flaq_sc2_nf.sh"

#### Note: some sample data files can be found in directory /fastqs/sample_data
