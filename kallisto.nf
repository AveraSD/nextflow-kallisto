#!/usr/bin/env nextflow

params.read1 = "/tmp/NA18238-b_S9_10k_1.fastq.gz"
params.read2 = "/tmp/NA18238-b_S9_10k_2.fastq.gz"
params.index = "/tmp/gencode.v19.lncRNA_transcripts.idx"
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
    stdout into results

    """
    kallisto quant -i $genome_index -o $outdir $read1 $read2
    """
}

results.subscribe { print it }
