#!/usr/bin/env nextflow

/*
 * params.read1 = "s3://averafastq/everything_else/NA18238-b_S9_10k_1.fastq.gz"
 * params.read2 = "s3://averafastq/everything_else/NA18238-b_S9_10k_2.fastq.gz"
 * params.index = "s3://averagenomedb/kallisto/gencode.v19.lncRNA_transcripts.idx"
 * params.out = "results/"
 */

params.read1 = "~/averalajolla/averafastq/everything_else/NA18238-b_S9_10k_1.fastq.gz"
params.read2 = "~/averalajolla/averafastq/everything_else/NA18238-b_S9_10k_2.fastq.gz"
params.index = "/data/kallisto/gencode.v19.lncRNA_transcripts.idx"
params.out = "results/"

log.info "Kallisto P I P E L I N E         "
log.info "================================="
log.info "index              : ${params.index}"
log.info "read1              : ${params.read1}"
log.info "read2              : ${params.read2}"
log.info ""
log.info "Current home       : $HOME"
log.info "Current user       : $USER"
log.info "Current path       : $PWD"
log.info "Script dir         : $baseDir"
log.info "Working dir        : $workDir"
log.info ""

genome_index = file(params.index)
read1 = file(params.read1)
read2 = file(params.read2)
out = file(params.out)
prefix = readPrefix(read1, '*_1.fastq.gz')

process kallisto {

    input:
    file genome_index
    file(read1)
    file(read2)
    file(out)
    
    output:
    file '*.abundance.h5' into results
    file '*.abundance.txt' into results
    file '*.run_info.json' into results
 
    """
    kallisto quant -i $genome_index -o /tmp $read1 $read2
    mv /tmp/abundance.h5 ./${prefix}.abundance.h5
    mv /tmp/abundance.txt ./${prefix}.abundance.txt
    mv /tmp/run_info.json ./${prefix}.run_info.json
    """
}

results.subscribe { 
    log.info "Copying results to file: ${out}/${it.name}"
    it.copyTo(out)
 }

/* 
 * Helper function, given a file Path 
 * returns the file name region matching a specified glob pattern
 * starting from the beginning of the name up to last matching group.
 * 
 * For example: 
 *   readPrefix('/some/data/file_alpha_1.fa', 'file*_1.fa' )
 * 
 * Returns: 
 *   'file_alpha'
 */
 
def readPrefix( Path actual, template ) {

    final fileName = actual.getFileName().toString()

    def filePattern = template.toString()
    int p = filePattern.lastIndexOf('/')
    if( p != -1 ) filePattern = filePattern.substring(p+1)
    if( !filePattern.contains('*') && !filePattern.contains('?') ) 
        filePattern = '*' + filePattern 
  
    def regex = filePattern.replace('.','\\.').replace('*','(.*)').replace('?','(.?)')

    def matcher = (fileName =~ /$regex/  )
    if( matcher.matches() ) { 
        def end = matcher.end(matcher.groupCount() )      
        def prefix = fileName.substring(0,end)
        while(prefix.endsWith('-') || prefix.endsWith('_') || prefix.endsWith('.') ) 
          prefix=prefix[0..-2]
          
        return prefix
    }
    
    return null
}