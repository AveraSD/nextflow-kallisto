#!/usr/bin/env nextflow

params.read1 = "s3://averafastq/everything_else/NA18238-b_S9_10k_1.fastq.gz"
params.read2 = "s3://averafastq/everything_else/NA18238-b_S9_10k_1.fastq.gz"
params.index = "s3://averagenomedb/kallisto/gencode.v19.lncRNA_transcripts.idx"
params.out = "~/tmp"
 
process kallisto {

    input:
    file(params.read1)
    file(params.read2)
    file(params.index)
    file(params.out)
  
    output:
    file '*'
 
    """
    kallisto quant -i $params.index -o $params.out $params.read1 $params.read2
    """
}
