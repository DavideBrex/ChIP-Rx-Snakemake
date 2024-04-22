rule bam2bigwig_general:
    input:
        bam="{}results/bam/{{id}}_ref.sorted.bam".format(outdir),
        logFile="{}results/logs/spike/{{id}}.removeSpikeDups".format(outdir),
        logFileInput=lambda wildcards: "{}results/logs/spike/{}.removeSpikeDups".format(
            outdir, sample_to_input[wildcards.id]
        )
        if not pd.isna(sample_to_input[wildcards.id])
        else "{}results/logs/spike/{{id}}.removeSpikeDups".format(outdir),
        blacklist=config["resources"]["ref"]["blacklist"],
    output:
        out="{}results/bigWigs/{{id}}.bw".format(outdir),
    params:
        extra=lambda wildcards: normalization_factor(wildcards),
        effective_genome_size=config["params"]["deeptools"]["effective_genome_length"],
    message:
        "Generating bigwig file for {input.bam} using bamCoverage"
    conda:
        "../envs/qc.yaml"
    log:
        "{}results/logs/bam2bigwig/{{id}}.log".format(outdir),
    threads: config["threads"]["generateBigWig"]
    benchmark:
        "{}results/.benchmarks/{{id}}.bigwigs.benchmark.txt".format(outdir)
    shell:
        """
        bamCoverage --blackListFileName {input.blacklist} \
                    {params.extra} \
                    --numberOfProcessors {threads} \
                    --effectiveGenomeSize {params.effective_genome_size} \
                    --bam {input.bam} \
                    --outFileName {output.out} \
                    --outFileFormat bigwig \
                    > {log} 2>&1
        """
