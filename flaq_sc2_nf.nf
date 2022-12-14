#!/usr/bin/env nextflow

/*
Note:
Before running the script, please set the parameters in the config file params.yaml
*/

//Step1:input data files
nextflow.enable.dsl=2
def L001R1Lst = []
def sampleNames = []
myDir = file("$params.input")

myDir.eachFileMatch ~/.*_1.fastq.gz/, {L001R1Lst << it.name}
L001R1Lst.sort()
L001R1Lst.each{
   def x = it.minus("_1.fastq.gz")
     //println x
   sampleNames.add(x)
}
//println L001R1Lst
//println sampleNames


//Step2: process the inputed data
A = Channel.fromList(sampleNames)
//A.view()

process quality {
   input:
      val x
   output:
      //stdout
      //path 'xfile.txt', emit: aLook
      val "${params.output}/${x}", emit: outputpath1
      //path "${params.output}/${x}_trim_2.fastq", emit: trimR2
      
   """  
   #echo ${params.input}/${x}_1.fastq.gz >> xfile.txt
   
   mkdir -p ${params.output}/assemblies
   mkdir -p ${params.output}/variants
   mkdir -p ${params.output}/vadr_error_reports
   mkdir -p ${params.output}/${x}
   cp ${params.input}/${x}_*.fastq.gz ${params.output}/${x}
   
   #Run fastqc on original reads
   singularity exec --cleanenv /apps/staphb-toolkit/containers/fastqc_0.11.9.sif fastqc ${params.output}/${x}/${x}_1.fastq.gz ${params.output}/${x}/${x}_2.fastq.gz
   mv ${params.output}/${x}/${x}_1_fastqc.html ${params.output}/${x}/${x}_1_original_fastqc.html
   mv ${params.output}/${x}/${x}_1_fastqc.zip ${params.output}/${x}/${x}_1_original_fastqc.zip
   mv ${params.output}/${x}/${x}_2_fastqc.html ${params.output}/${x}/${x}_2_original_fastqc.html
   mv ${params.output}/${x}/${x}_2_fastqc.zip ${params.output}/${x}/${x}_2_original_fastqc.zip
   
   #Run trimmomatic
   #singularity exec --cleanenv /apps/staphb-toolkit/containers/trimmomatic_0.39.sif trimmomatic PE -phred33 -trimlog ${params.output}/${x}/${x}.log ${params.output}/${x}/${x}_1.fastq.gz ${params.output}/${x}/${x}_2.fastq.gz ${params.output}/${x}/${x}_trim_1.fastq.gz ${params.output}/${x}/${x}_unpaired_trim_1.fastq.gz ${params.output}/${x}/${x}_trim_2.fastq.gz ${params.output}/${x}/${x}_unpaired_trim_2.fastq.gz ILLUMINACLIP:/Trimmomatic-0.39/adapters/NexteraPE-PE.fa:2:30:10 SLIDINGWINDOW:5:20 MINLEN:71 TRAILING:20
   singularity exec --cleanenv /apps/staphb-toolkit/containers/trimmomatic_0.39.sif trimmomatic PE -phred33 -trimlog ${params.output}/${x}/${x}.log ${params.output}/${x}/${x}_1.fastq.gz ${params.output}/${x}/${x}_2.fastq.gz ${params.output}/${x}/${x}_trim_1.fastq.gz ${params.output}/${x}/${x}_unpaired_trim_1.fastq.gz ${params.output}/${x}/${x}_trim_2.fastq.gz ${params.output}/${x}/${x}_unpaired_trim_2.fastq.gz SLIDINGWINDOW:4:30 MINLEN:75 TRAILING:20 > ${params.output}/${x}/${x}_trimstats.txt
   rm ${params.output}/${x}/${x}_unpaired_trim_*.fastq.gz
   #rm ${params.output}/${x}/${x}_1.fastq.gz ${params.output}/${x}/${x}_2.fastq.gz

   #Run bbduk to remove Illumina adapter sequences and any PhiX contamination  
   singularity exec --cleanenv /apps/staphb-toolkit/containers/bbtools_38.76.sif bbduk.sh in1=${params.output}/${x}/${x}_trim_1.fastq.gz in2=${params.output}/${x}/${x}_trim_2.fastq.gz out1=${params.output}/${x}/${x}_1.rmadpt.fq.gz out2=${params.output}/${x}/${x}_2.rmadpt.fq.gz ref=/bbmap/resources/adapters.fa stats=${params.output}/${x}/${x}.adapters.stats.txt ktrim=r k=23 mink=11 hdist=1 tpe tbo
   singularity exec --cleanenv /apps/staphb-toolkit/containers/bbtools_38.76.sif bbduk.sh in1=${params.output}/${x}/${x}_1.rmadpt.fq.gz in2=${params.output}/${x}/${x}_2.rmadpt.fq.gz out1=${params.output}/${x}/${x}_1.fq.gz out2=${params.output}/${x}/${x}_2.fq.gz outm=${params.output}/${x}/${x}_matchedphix.fq ref=/bbmap/resources/phix174_ill.ref.fa.gz k=31 hdist=1 stats=${params.output}/${x}/${x}_phixstats.txt
   rm ${params.output}/${x}/${x}_trim*.fastq.gz
   rm ${params.output}/${x}/${x}*rmadpt.fq.gz
   
   #Run fastqc on clean forward and reverse reads
   singularity exec --cleanenv /apps/staphb-toolkit/containers/fastqc_0.11.9.sif fastqc ${params.output}/${x}/${x}_1.fq.gz ${params.output}/${x}/${x}_2.fq.gz
   #Rename fastqc output files
   mv ${params.output}/${x}/${x}_1_fastqc.html ${params.output}/${x}/${x}_1_clean_fastqc.html
   mv ${params.output}/${x}/${x}_1_fastqc.zip ${params.output}/${x}/${x}_1_clean_fastqc.zip
   mv ${params.output}/${x}/${x}_2_fastqc.html ${params.output}/${x}/${x}_2_clean_fastqc.html
   mv ${params.output}/${x}/${x}_2_fastqc.zip ${params.output}/${x}/${x}_2_clean_fastqc.zip
   
   #Run multiqc
   singularity exec --cleanenv /apps/staphb-toolkit/containers/multiqc_1.8.sif multiqc ${params.output}/${x}/${x}_*_fastqc.zip -o ${params.output}/${x}
   
   #Map reads to reference
   mkdir ${params.output}/${x}/alignment
   """
}

process nofrag {
    input:
        val mypath
    output:
        //stdout
        val mypath
        //path "pyoutputs.txt", emit: pyoutputs
        
    
    """
    samplename=\$(echo ${mypath} | rev | cut -d "/" -f 1 | rev)
    singularity exec /apps/staphb-toolkit/containers/bwa_0.7.17.sif bwa mem ${params.reference}/nCoV-2019.reference.fasta ${mypath}/\${samplename}_1.fq.gz ${mypath}/\${samplename}_2.fq.gz | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools view - -F 4 -u -h | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort > ${mypath}/alignment/\${samplename}.sorted.bam
    #Index final sorted bam
    #singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools index ${mypath}/alignment/\${samplename}.sorted.bam
    
    """
}

process frag {
    input:
        val mypath
 
    output:
        //stdout
        val mypath
        //path "pyoutputs.txt", emit: pyoutputs

    """
    samplename=\$(echo ${mypath} | rev | cut -d "/" -f 1 | rev)
    #singularity exec /apps/staphb-toolkit/containers/bwa_0.7.17.sif bwa mem ${params.reference}/nCoV-2019.reference.fasta ${mypath}/\${samplename}_1.fq.gz ${mypath}/\${samplename}_2.fq.gz | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools view - -F 4 -u -h | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort > ${mypath}/alignment/\${samplename}.sorted.bam
    
    singularity exec /apps/staphb-toolkit/containers/bwa_0.7.17.sif bwa mem ${params.reference}/nCoV-2019.reference.fasta ${mypath}/\${samplename}_1.fq.gz ${mypath}/\${samplename}_2.fq.gz | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools view - -F 4 -u -h | singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort -n > ${mypath}/alignment/\${samplename}.namesorted.bam
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools fixmate -m ${mypath}/alignment/\${samplename}.namesorted.bam ${mypath}/alignment/\${samplename}.fixmate.bam
        #Create positional sorted bam from fixmate.bam
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort -o ${mypath}/alignment/\${samplename}.positionsort.bam ${mypath}/alignment/\${samplename}.fixmate.bam
        #Mark duplicate reads
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools markdup ${mypath}/alignment/\${samplename}.positionsort.bam ${mypath}/alignment/\${samplename}.markdup.bam
        #Remove duplicate reads
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools markdup -r ${mypath}/alignment/\${samplename}.positionsort.bam ${mypath}/alignment/\${samplename}.dedup.bam
        #Sort dedup.bam and rename to .sorted.bam
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort -o ${mypath}/alignment/\${samplename}.sorted.bam ${mypath}/alignment/\${samplename}.dedup.bam
       #Index final sorted bam
    #singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools index ${mypath}/alignment/\${samplename}.sorted.bam
    """
}

process primer {
    input:
        val mypath
 
    output:
        //stdout
        val mypath
        //path "pyoutputs.txt", emit: pyoutputs
        
    
    """
    samplename=\$(echo ${mypath} | rev | cut -d "/" -f 1 | rev)
    #Index final sorted bam
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools index ${mypath}/alignment/\${samplename}.sorted.bam
    
    #Trim primers with iVar
    ivar trim -i ${mypath}/alignment/\${samplename}.sorted.bam  -b ${params.primer}/ARTIC-V4.1.bed -p ${mypath}/alignment/\${samplename}.primertrim -e
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools sort ${mypath}/alignment/\${samplename}.primertrim.bam -o ${mypath}/alignment/\${samplename}.primertrim.sorted.bam
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools index ${mypath}/alignment/\${samplename}.primertrim.sorted.bam
    singularity exec /apps/staphb-toolkit/containers/samtools_1.12.sif samtools coverage ${mypath}/alignment/\${samplename}.primertrim.sorted.bam -o ${mypath}/alignment/\${samplename}.coverage.txt
    """
}

process assembly {
    input:
        val mypath
    output:
        //stdout
        val mypath
        //path "pyoutputs.txt", emit: pyoutputs
        
    
    """ 
    samplename=\$(echo ${mypath} | rev | cut -d "/" -f 1 | rev)
    #Call variants
    mkdir ${mypath}/variants
    samtools mpileup -A -d 8000 --reference ${params.reference}/nCoV-2019.reference.fasta -B -Q 0 ${mypath}/alignment/\${samplename}.primertrim.sorted.bam | ivar variants -r ${params.reference}/nCoV-2019.reference.fasta -m 10 -p ${mypath}/variants/\${samplename}.variants -q 20 -t 0.25 -g ${params.reference}/GCF_009858895.2_ASM985889v3_genomic.gff

    #Generate consensus assembly
    mkdir ${mypath}/assembly
    samtools mpileup -A -B -d 8000 --reference ${params.reference}/nCoV-2019.reference.fasta -Q 0 ${mypath}/alignment/\${samplename}.primertrim.sorted.bam | ivar consensus -t 0 -m 10 -n N -p ${mypath}/assembly/\${samplename}.consensus
    
    """
}
process pystats {
    input:
        val mypath
    output:
        stdout
        //val mypath
        //path "pyoutputs.txt", emit: pyoutputs
        
    $/
    #!/usr/bin/env python3
    import subprocess
    
    items = "${mypath}".strip().split("/")
    #print(items[-1])
    filepath1 = "${mypath}"+"/alignment/"+items[-1]+".coverage.txt"
    #print(filepath1)
    with open(filepath1, 'r') as cov_report:
        header = cov_report.readline()
        header = header.rstrip()
        stats = cov_report.readline()
        stats = stats.rstrip()
        stats = stats.split()
        ref_name = stats[0]
        #print(ref_name)
        start = stats[1]
        end = stats[2]
        reads_mapped = stats[3]
        cov_bases = stats[4]
        cov = stats[5]
        depth = stats[6]
        baseq = stats[7]
        #print(reads_mapped)
        mapq = stats[8]
        
    #Get number of raw reads
    proc_1 = subprocess.run('zcat ' + "${mypath}/" + items[-1] + '_1.fastq.gz | wc -l', shell=True, capture_output=True, text=True, check=True)
    wc_out_1 = proc_1.stdout.rstrip()
    reads_1 = int(wc_out_1) / 4
    proc_2 = subprocess.run('zcat ' + "${mypath}/" + items[-1] + '_2.fastq.gz | wc -l', shell=True, capture_output=True, text=True, check=True)
    wc_out_2 = proc_2.stdout.rstrip()
    reads_2 = int(wc_out_2) / 4
    raw_reads = reads_1 + reads_2
    raw_reads = int(raw_reads)

    #Get number of clean reads
    proc_c1x = subprocess.run('zcat ' + "${mypath}/" + items[-1] + '_1.fq.gz | wc -l', shell=True, capture_output=True, text=True, check=True)
    wc_out_c1x = proc_c1x.stdout.rstrip()
    reads_c1x = int(wc_out_c1x) / 4
    proc_c2x = subprocess.run('zcat ' + "${mypath}/" + items[-1] + '_2.fq.gz | wc -l', shell=True, capture_output=True, text=True, check=True)
    wc_out_c2x = proc_c2x.stdout.rstrip()
    reads_c2x = int(wc_out_c2x) / 4
    clean_reads = reads_c1x + reads_c2x
    clean_reads = int(clean_reads)
    #print(clean_reads)
    
    #Get percentage of mapped reads/clean reads
    percent_map = "%0.4f"%((int(reads_mapped)/int(clean_reads))*100)
    #print(percent_map)
    
    #Gather QC metrics for consensus assembly
    filepath2 = "${mypath}"+"/assembly/"+items[-1]+".consensus.fa"
    with open(filepath2, 'r') as assem:
        header = assem.readline()
        header = header.rstrip()
        bases = assem.readline()
        bases = bases.rstrip()
        num_bases = len(bases)
        ns = bases.count('N')
        called = num_bases - ns
        pg = "%0.4f"%((called/int(end))*100)
        #print(called)
        #print(end)
        #print(pg)
    #Rename header in fasta to just sample name
    subprocess.run("sed -i \'s/^>.*/>"+items[-1]+"/\' "+filepath2, shell=True, check=True)
    #print("sed -i \'s/^>.*/>"+items[-1]+"/\' "+filepath2)
    
    #QC flag
    pg_flag = ''
    dp_flag = ''
    qc_flag = ''
    if float(pg) < 79.5:
        pg_flag = 'FAIL: Percent genome < 80%'
        qc_flag = qc_flag + pg_flag
    else:
        if float(depth) < 100:
            dp_flag = 'FAIL: Mean read depth < 100x'
            qc_flag = qc_flag + dp_flag
        if qc_flag == '':
            qc_flag = qc_flag + 'PASS'
    #print(qc_flag)
    
    if qc_flag == 'PASS':
        subprocess.run("cp "+filepath2+" "+"${params.output}"+"/assemblies/", shell=True, check=True)   
        subprocess.run('cp ' + "${mypath}" + '/variants/' + items[-1] + '.variants.tsv ' + "${params.output}"+'/variants/', shell=True, check=True)
    
        #Run VADR
        out_log = open("${mypath}/"+items[-1]+'.out', 'w')
        err_log = open("${mypath}/"+items[-1]+'.err', 'w')
        subprocess.run("singularity exec -B "+"${mypath}"+"/assembly"+":/data /apps/staphb-toolkit/containers/vadr_1.3.sif /opt/vadr/vadr/miniscripts/fasta-trim-terminal-ambigs.pl --minlen 50 --maxlen 30000 /data/" + items[-1]+".consensus.fa > " + "${mypath}"+"/assembly/"+items[-1]+".trimmed.fasta", shell=True, stdout=out_log, stderr=err_log, check=True)
        subprocess.run("singularity exec -B "+"${mypath}"+"/assembly:/data /apps/staphb-toolkit/containers/vadr_1.3.sif v-annotate.pl --split --cpu 8 --glsearch -s -r --nomisc --mkey sarscov2 --lowsim5seq 6 --lowsim3seq 6 --alt_fail lowscore,insertnn,deletinn --mdir /opt/vadr/vadr-models/ /data/"+items[-1]+".trimmed.fasta -f /data/"+"vadr_results", shell=True, stdout=out_log, stderr=err_log, check=True)

        #Parse through VADR outputs to get PASS or REVIEW flag
        vadr_flag = ''
        with open("${mypath}"+"/assembly/vadr_results/vadr_results.vadr.pass.list", 'r') as p_list:
            result = p_list.readline()
            result = result.rstrip()
            if result == items[-1]:
                vadr_flag = 'PASS'

        with open("${mypath}"+"/assembly/vadr_results/vadr_results.vadr.fail.list", 'r') as f_list:
            result = f_list.readline()
            result = result.rstrip()
            if result == items[-1]:
                vadr_flag = 'REVIEW'

        #Copy VADR error report to main analysis folder for easier review
        if vadr_flag == 'REVIEW':
            subprocess.run("cp " + "${mypath}"+"/assembly/vadr_results/vadr_results.vadr.alt.list "+"${params.output}"+"/vadr_error_reports/"+items[-1]+".vadr.alt.list", shell=True, check=True)
            #subprocess.run('mv vadr_error_reports/vadr_results.vadr.alt.list vadr_error_reports/' + s + '.vadr.alt.list', shell=True, check=True)
            #print("cp " + "${mypath}"+"/assembly/vadr_results/vadr_results.vadr.alt.list "+"${params.output}"+"/vadr_error_reports/"+items[-1]+".vadr.alt.list")

        #Run pangolin
        ###--pango_path /apps/staphb-toolkit/containers/pangolin_4.1.2-pdata-1.13.sif --pangolin v4.1.2 --pangolin_data v1.13
        pangolin = "v4.1.2_pdata-v1.13"
        subprocess.run('singularity exec -B '+"${mypath}"+"/assembly:/data /apps/staphb-toolkit/containers/pangolin_4.1.2-pdata-1.13.sif" + ' pangolin -o /data /data/'+items[-1]+".consensus.fa", shell=True, check=True)

        #Get lineage
        proc = subprocess.run("tail -n 1 "+"${mypath}"+"/assembly/lineage_report.csv | cut -d \',\' -f 2", shell=True, check=True, capture_output=True, text=True)
        lineage = proc.stdout.rstrip()
        #print(lineage)

        #Run nextclade
        subprocess.run("singularity exec -B "+"${mypath}"+"/assembly:/data /apps/staphb-toolkit/containers/nextclade_2021-03-15.sif nextclade --input-fasta /data/"+items[-1]+".consensus.fa --output-csv /data/nextclade_report.csv", shell=True, check=True)

        #Parse nextclade output and screen for sotc
        sotc_v = "${params.sotc}".split(',')
        with open("${mypath}"+"/assembly/nextclade_report.csv", 'r') as nc:
            header = nc.readline()
            c_results = nc.readline()
            c_results = c_results.rstrip()
            data = c_results.split(',')
            #print(data)
            sotc = []
            for v in sotc_v:
                print(v)
                if v in data:
                    sotc.append(v)
            sotc_out = (',').join(sotc)
        out_log.close()
        err_log.close()
    else:
        vadr_flag = 'NA'
        lineage = 'NA'
        sotc_out = 'NA'
        
    with open("${mypath}"+"/report.txt", 'w') as report:
        header = ['sampleID', 'reference', 'start', 'end', 'num_raw_reads', 'num_clean_reads', 'num_mapped_reads', 'percent_mapped_clean_reads', 'cov_bases_mapped', 'percent_genome_cov_map', 'mean_depth', 'mean_base_qual', 'mean_map_qual', 'assembly_length', 'numN', 'percent_ref_genome_cov', 'VADR_flag', 'QC_flag', 'pangolin_version', 'lineage', 'SOTC']
        report.write('\t'.join(map(str,header)) + '\n')
        results = [items[-1], ref_name, start, end, raw_reads, clean_reads, reads_mapped, percent_map, cov_bases, cov, depth, baseq, mapq, num_bases, ns, pg, vadr_flag, qc_flag, pangolin, lineage, sotc_out]
        report.write('\t'.join(map(str,results)) + '\n')
    /$
}


workflow {
    if("${params.frag}" == "frag"){
       quality(A) | frag | primer | assembly | pystats | view
    }
    else{
       quality(A) | nofrag | primer | assembly | pystats | view
    }
}


