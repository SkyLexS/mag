process RESMICO_BAM2FEAT {
    tag "$meta.id"
    label 'process_medium'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://community.wave.seqera.io/library/resmico_samtools_numpy_setuptools:50dc5f9a6dacdffe':
        'community.wave.seqera.io/library/resmico_samtools_numpy_setuptools:50dc5f9a6dacdffe' }"

    input:
    tuple val(meta), path(fasta), path(bam), path(bai)

    output:
    tuple val(meta), path("resmico_features")                  , emit: features_dir
    tuple val(meta), path("resmico_features/feature_files.tsv"), emit: feature_files_tsv
    path "versions.yml"                                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2.2' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    # Build input table required by resmico bam2feat
    echo -e "Taxon\\tFasta\\tSample\\tBAM" > input_table.tsv
    echo -e "${meta.id}\\t${fasta}\\t${meta.id}\\t${bam}" >> input_table.tsv

    # queue-size 1: forces synchronous writes, preventing race condition between
    #               the computation thread and the async writer thread (SIGSEGV)
    resmico bam2feat \\
        --outdir resmico_features \\
        ${args} \\
        --queue-size 1 \\
        input_table.tsv

    if [[ ! -f resmico_features/feature_files.tsv ]]; then
        echo -e "Taxon\\tSample\\tfeature_file" > resmico_features/feature_files.tsv
        echo -e "${meta.id}\\t${meta.id}\\t/data/resmico_features" >> resmico_features/feature_files.tsv
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resmico: ${VERSION}
END_VERSIONS
    """

    stub:
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2.2'
    """
    mkdir -p resmico_features/${meta.id}/${meta.id}
    touch resmico_features/feature_files.tsv
    touch resmico_features/${meta.id}/${meta.id}/features_binary
    touch resmico_features/${meta.id}/${meta.id}/features_binary_chunked
    touch resmico_features/${meta.id}/${meta.id}/stats
    touch resmico_features/${meta.id}/${meta.id}/toc
    touch resmico_features/${meta.id}/${meta.id}/toc_chunked

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resmico: ${VERSION}
END_VERSIONS
    """
}
