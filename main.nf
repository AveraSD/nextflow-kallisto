#!/usr/bin/env nextflow

params.read1 = "s3://averafastq/everything_else/NA18238-b_S9_10k_1.fastq.gz"
params.read2 = "s3://averafastq/everything_else/NA18238-b_S9_10k_2.fastq.gz"
params.index = "s3://averagenomedb/kallisto/gencode.v19.lncRNA_transcripts.idx"
params.out = "/tmp"
 
genome_index = file(params.index)
read1 = file(params.read1)
read2 = file(params.read2)
outdir = file(params.out)

process kallisto {

    input:
    file read1
    file read2
    file genome_index
    file outdir
    
    output:
    file 'abundance.h5'
    file 'abundance.txt'
    file 'run_info.json'
 
    """
    kallisto quant -i $genome_index -o $outdir $read1 $read2
    """
}
