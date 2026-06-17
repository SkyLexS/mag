process RESMICO_EVALUATE {
    tag "$meta.id"
    label 'process_medium'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://community.wave.seqera.io/library/resmico_samtools_numpy_setuptools:50dc5f9a6dacdffe':
        'community.wave.seqera.io/library/resmico_samtools_numpy_setuptools:50dc5f9a6dacdffe' }"

    input:
    tuple val(meta), path(features_dir)

    output:
    tuple val(meta), path("*_predictions.csv"), emit: predictions
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2.2' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    resmico evaluate \\
        --feature-files-path ${features_dir} \\
        --save-path . \\
        --save-name ${prefix} \\
        --n-procs ${task.cpus} \\
        ${args}

    if [[ -f "${prefix}.csv" ]]; then
        mv "${prefix}.csv" "${prefix}_predictions.csv"
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
    touch ${prefix}_predictions.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resmico: ${VERSION}
END_VERSIONS
    """
}
