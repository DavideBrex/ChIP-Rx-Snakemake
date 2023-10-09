if config["aligner"] == "bowtie":

    rule align_bowtie:
        input:
            reads=get_reads,
            idx="resources/reference_genome/genome/",
        output:
            bam=temp("results/bam/{id}.tmp.bam"),
            index=temp("results/bam/{id}.tmp.bam.bai"),
        threads: 8
        params:
            index=config["resources"]["ref"]["index"]
            if config["resources"]["ref"]["index"] != ""
            else "resources/reference_genome/genome/genome",
            bowtie=config["params"]["bowtie"]["global"],
            samtools_mem=config["params"]["samtools"]["memory"],
            inputsel=(
                lambda wildcards, input: input.reads
                if len(input.reads) == 1
                else config["params"]["bowtie"]["pe"]
                + " -1 {0} -2 {1}".format(*input.reads)
            ),
        message:
            "Aligning {input} with parameters {params.bowtie}"
        conda:
            "../envs/bowtie.yaml"
        log:
            align="results/logs/alignments/{id}.log",
            rm_dups="results/logs/alignments/rm_dup/{id}.log",
        benchmark:
            "results/.benchmarks/{id}.align.benchmark.txt"
        shell:
            """
            bowtie -p {threads} {params.bowtie} -x {params.index} {params.inputsel} 2> {log.align} \
            | samblaster --removeDups 2> {log.rm_dups} \
            | samtools view -Sb -F 4 - \
            | samtools sort -m {params.samtools_mem}G -@ {threads} -T {output.bam}.tmp -o {output.bam} - 2>> {log.align}
            samtools index {output.bam}
            """

    # SPIKE alignment
    rule align_bowtie_spike:
        input:
            reads=get_reads,
            idx="resources/spike_genome/genome/",
        output:
            bam=temp("results/bam_spike/{id}_spike.tmp.bam"),
            index=temp("results/bam_spike/{id}_spike.tmp.bam.bai"),
        threads: 8
        params:
            index=config["resources"]["ref_spike"]["index_spike"]
            if config["resources"]["ref_spike"]["index_spike"] != ""
            else "resources/spike_genome/genome/genome",
            bowtie=config["params"]["bowtie"]["global"],
            samtools_mem=config["params"]["samtools"]["memory"],
            inputsel=(
                lambda wildcards, input: input.reads
                if len(input.reads) == 1
                else config["params"]["bowtie"]["pe"]
                + " -1 {0} -2 {1}".format(*input.reads)
            ),
        message:
            "SPIKE-IN - Aligning {input} with parameters {params.bowtie}"
        conda:
            "../envs/bowtie.yaml"
        log:
            align="results/logs/alignments/spike/{id}_spike.log",
            rm_dups="results/logs/alignments/spike/rm_dup/{id}_spike.log",
        benchmark:
            "results/.benchmarks/{id}.align.benchmark.txt"
        shell:
            """
            bowtie -p {threads} {params.bowtie} -x {params.index} {params.inputsel} 2> {log.align} \
            | samblaster --removeDups 2> {log.rm_dups} \
            | samtools view -Sb -F 4 - \
            | samtools sort -m {params.samtools_mem}G -@ {threads} -T {output.bam}.tmp -o {output.bam} - 2>> {log.align}
            samtools index {output.bam}
            """


rule clean_spike:
    input:
        sample_ref="results/bam/{id}.tmp.bam",
        sample_spike="results/bam_spike/{id}_spike.tmp.bam",
        sample_ref_index="results/bam/{id}.tmp.bam.bai",
        sample_spike_index="results/bam_spike/{id}_spike.tmp.bam.bai",
    output:
        sample_ref="results/bam/{id}.clean.bam",
        sample_spike="results/bam_spike/{id}_spike.clean.bam",
    conda:
        "../envs/pysam.yaml"
    log:
        "results/logs/spike/{id}.removeSpikeDups",
    script:
        "../scripts/remove_spikeDups.py"
