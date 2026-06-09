process RESMICO_FILTER {
    tag "$meta.id"
    label 'process_low'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "quay.io/resmico-with-samtools:latest"

    input:
    tuple val(meta), path(predictions_csv), path(fasta)

    output:
    tuple val(meta), path("resmico_filtered/${fasta.getName()}"), emit: filtered_fasta
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2.2' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    resmico filter \\
        --outdir resmico_filtered \\
        ${args} \\
        ${predictions_csv} \\
        ${fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resmico: ${VERSION}
    END_VERSIONS
    """

    stub:
    def VERSION = '1.2.2'
    """
    mkdir -p resmico_filtered
    touch resmico_filtered/${fasta.getName()}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resmico: ${VERSION}
    END_VERSIONS
    """
}
