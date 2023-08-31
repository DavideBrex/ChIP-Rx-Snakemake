



if config["aligner"] == "bowtie":


    rule align_bowtie:
        input:
            reads=get_reads,
            idx= directory("resources/reference_genome/genome/")
            
        output:
            bam   = "results/bam/{id}.bam",
            index = "results/bam/{id}.bam.bai"
        threads:
            8
        params:
            index        =  config["resources"]["ref"]["index"]
                            if config["resources"]["ref"]["index"] != "" 
                            else "resources/reference_genome/genome/genome",
            bowtie 	     =  config["params"]["bowtie"]["global"],
            samtools_mem =  config["params"]["samtools"]["memory"],
            inputsel  	 =  (
                                lambda wildcards, input: input.reads
                                if len(input.reads) == 1
                                else 
                                    config["params"]["bowtie"]["pe"] + " -1 {0} -2 {1}".format(*input.reads)
                            )
        message:
            "Aligning {input} with parameters {params.bowtie}"
        conda:
            "../envs/bowtie.yaml"
        log:
            align   = "results/logs/alignments/{id}.log",
            rm_dups = "results/logs/alignments/rm_dup/{id}.log",
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

