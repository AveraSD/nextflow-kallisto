#!/usr/bin/env nextflow

params.read1 = Channel.fromPath('./data/*_1.fastq.gz')
params.read2 = Channel.fromPath('./data/*_2.fastq.gz')
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
log.info "Output dir         : ${params.out}"
log.info ""

genome_index = file(params.index)
out = file(params.out, type: 'dir')

process kallisto {

    input:
    file genome_index
    file read1 from params.read1
    file read2 from params.read2

    output:
    file '*.abundance.h5' into results
    file '*.abundance.txt' into results
    file '*.run_info.json' into results

    """
    prefix=\$(echo $read1 | sed 's/_.*//')
    kallisto quant -i $genome_index -o /tmp $read1 $read2
    mv /tmp/abundance.h5 ./\$prefix.abundance.h5
    mv /tmp/abundance.txt ./\$prefix.abundance.txt
    mv /tmp/run_info.json ./\$prefix.run_info.json
    """
}

results.subscribe {
    log.info "Copying results to file: ${out}/${it.name}"
    it.copyTo(out)
<<<<<<< HEAD
}
=======
 }
>>>>>>> 16884c45588e322c7149c14301549ba0be349e97
