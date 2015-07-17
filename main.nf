#!/usr/bin/env nextflow

/*
 * params.read1 = "s3://averafastq/everything_else/NA18238-b_S9_10k_1.fastq.gz"
 * params.read2 = "s3://averafastq/everything_else/NA18238-b_S9_10k_2.fastq.gz"
 * params.index = "s3://averagenomedb/kallisto/gencode.v19.lncRNA_transcripts.idx"
 * params.out = "/shared"
 */

params.read1 = "~/averalajolla/averafastq/everything_else/NA18238-b_S9_10k_1.fastq.gz"
params.read2 = "~/averalajolla/averafastq/everything_else/NA18238-b_S9_10k_2.fastq.gz"
params.index = "/data/kallisto/gencode.v19.lncRNA_transcripts.idx"
params.out = "/data/test"

log.info "Kallisto P I P E L I N E         "
log.info "================================="
log.info "index              : ${params.index}"
log.info "read1              : ${params.read1}"
log.info "read2              : ${params.read2}"
log.info "output dir         : ${params.out}"
log.info ""
log.info "Current home       : $HOME"
log.info "Current user       : $USER"
log.info "Current path       : $PWD"
log.info "Script dir         : $baseDir"
log.info "Working dir        : $workDir"
log.info ""

/*
 * emits all reads ending with "_1" suffix and map them to pair containing the common
 * part of the name
 */
Channel
    .fromPath( params.read1 )
    .ifEmpty { error "Cannot find any reads matching: ${params.read1}" }
    .map { path -> 
       def prefix = readPrefix(path, params.read1)
       tuple(prefix, path) 
    }
    .set { reads1 } 
  
/*
 * as above for "_2" read pairs
 */
Channel
    .fromPath( params.read2 )
    .ifEmpty { error "Cannot find any reads matching: ${params.read2}" }
    .map { path -> 
       def prefix = readPrefix(path, params.read2)
       tuple(prefix, path) 
    }
    .set { reads2 }     
     
/*
 * Match the pairs emittedb by "read1" and "read2" channels having the same 'key'
 * and emit a new pair containing the expected read-pair files
 */
reads1
    .phase(reads2)
    .ifEmpty { error "Cannot find any matching reads" }
    .map { read1, read2 -> tuple(read1[0], read1[1], read2[1]) }
    .set { read_pairs } 

/*
 * the reference index
 */
genome_index = file(params.index)

/*
 * the output
 */
outdir = file(params.out)

process kallisto {
    tag "$pair_id"

    input:
    file genome_index
    file outdir
    set pair_id, file(read1), file(read2) from read_pairs
    
    output:
    set pair_id, 'abundance.h5' into results
    set pair_id, 'abundance.txt' into results
    set pair_id, 'run_info.json' into results
 
    """
    kallisto quant -i $genome_index -o $outdir $read1 $read2
    """
}

/*
 * Step 4. collect the results and save them
 */
results
  .subscribe { tuple ->
    def fileName = "abundance_${tuple[0]}.h5" 
    tuple[1].copyTo(fileName)
    println "Saving: $fileName"
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