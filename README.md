<img align="left"  width="55%" src="LogoSpikeFlow.png">

<br clear="left"/>

### A snakemake pipeline for the analysis of ChIP-Rx data 

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.3.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/DavideBrex/SpikeFlow/workflows/Tests/badge.svg?branch=main)](https://github.com/DavideBrex/SpikeFlow/actions?query=branch%3Amain+workflow%3ATests)
[![DOI](https://zenodo.org/badge/665587139.svg)](https://zenodo.org/doi/10.5281/zenodo.10686979)



If you use this workflow in a paper, don't forget to give credits to the authors. See the [citation](#citation) section.

## About

**SpikeFlow** is a Snakemake-based workflow designed for the analysis of ChIP-seq data with spike-in normalization (i.e. ChIP-Rx). Spike-in controls are used to provide a reference for normalizing sample-to-sample variation. These controls are typically DNA from a different species added to each ChIP and input sample in consistent amounts. This workflow facilitates accurate and reproducible chromatin immunoprecipitation studies by integrating state-of-the-art computational methodologies.
 
**Key Features**:

- **Diverse Normalization Techniques**: This workflow implements five normalization methods,to accommodate varying experimental designs and enhance data comparability. These are: RPM, RRPM, Rx-Input, Downsampling, and Median.

- **Quality Control**:  Spike-in quality control, to ensure a proper comparison between different experimental conditions

- **Peak Calling**: The workflow incorporates three algorithms for peak identification, crucial for delineating protein-DNA interaction sites. The user can choose the type of peak to be called: narrow (macs2), broad (epic2), or very-broad (edd). Moreover, the pipeline allows to call spike-in normalised peaks (only narrow and broad modes).

- **BigWig Generation for Visualization**: Normalised BigWig files are generated for genome-wide visualization, compatible with standard genomic browsers, thus facilitating detailed chromatin feature analyses.

- **Differential Peak Analysis**: If needed, the user can enable spike-in normalized differential peak analysis. The pipeline will generate PCA and Volcano plots to facilitate the interpretation of the results.

- **Scalability**: Leveraging Snakemake, the workflow ensures an automated, error-minimized pipeline adaptable to both small and large-scale genomic datasets.


**Currently supported genomes**:

- Endogenous: mm9, mm10, hg19, hg38
- Exogenous (spike-in): dm3, dm6, mm10, mm9, hg19, hg38, hs1


## Table of Contents


1. [Installation](#install)
2. [Configuration](#config)
3. [Run the workflow](#run)
4. [Output files](#output)
5. [Troubleshooting](#troubleshooting)
6. [Citation](#citation)


<a name="install"></a>
## Installation 
### Step 1 - Install a Conda-based Python3 distribution

If you do not already have Conda installed on your machine/server, install a Conda-based Python3 distribution. We recommend [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge), which includes Mamba, a fast and robust replacement for the Conda package manager. Mamba is preferred over the default Conda solver due to its speed and reliability.

> **_⚠️ NOTE:_** Conda (or Mamba) is needed to run SpikeFlow.

### Step 1 - Install Snakemake
To run this pipeline, you'll need to install **Snakemake** (version >= 6.3.0).
Please check the Snakemake documentation on [how to install](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).
Once you have *conda* installed, you can simply create a new environment and install Snakemake with:

```
conda create -c bioconda -c conda-forge -n snakemake snakemake
```

For mamba, use the following code:

```
 mamba create -c conda-forge -c bioconda -n snakemake snakemake
```


Once the environment is created, activate it with:
```
conda activate snakemake
```
or
```
mamba activate snakemake
```

### Step 2 - Install Singularity (recommended)

For a fast installation of the workflow, it is recommended to use **Singularity** (compatible with version 3.9.5). This bypasses the need for *Conda* to set up required environments, as these are already present within the container that will be pulled from [dockerhub](https://hub.docker.com/r/davidebrex/spikeflow) with the use of the ```--use-singularity``` flag.

To install singularity check [its website](https://docs.sylabs.io/guides/3.0/user-guide/installation.html).

### Step 3 - Download SpikeFlow

To obtain SpikeFlow, you can:

1.  Download the source code as zip file from the latest [version](https://github.com/DavideBrex/SpikeFlow/releases/latest).

2.  Clone the repository on your local machine. See [here](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) the instructions.

### Step 4 - Test the workflow

Once you obtained the latest version of SpikeFlow, the ```config.yaml```  and the ```samples_sheet.csv```  files are already set to run an installation test. 
You can open them to have an idea about their structure. 
All the files needed for the test are in the ```.test``` folder (on ubuntu, type *ctrl + h* to see hidden files and folders).
To test whether SpikeFlow is working properly, jump directly to the [Run the workflow](#run) section of the documentation.


The usage of this workflow is also described in the [Snakemake Workflow Catalog](https://snakemake.github.io/snakemake-workflow-catalog/?usage=DavideBrex%2FSpikeFlow).

<a name="config"></a>
## Configuration

### 1. **Sample Sheet Input Requirements**

Prior to executing the pipeline, you need to prepare a sample sheet containing detailed information about the samples to analyse. You can find an example of this file under ```config/samples_sheet.csv```.
The required format is a comma-separated values (CSV) file, consisting of eight columns and including a header row.
For each sample (row), you need to specify:

| Column Name           | Description                                                                                             	|
|-------------------	|----------------------------------------------------------------------------------------------------------	|
| sample            	| Unique sample name                                                                                       	|
| replicate         	| Integer indicating the number of replicate (if no replicate simply add 1)                                	|
| antibody          	| Antibody used for the experiment (leave empty for Input samples)                                         	|
| control           	| Unique sample name of the control (it has to be specified also in the sample column, but in another row) 	|
| control_replicate 	| Integer indicating the number of replicate for the control sample (if no replicate simply add 1)         	|
| peak_type         	| Can only be equal to: narrow, broad, very-broad. It indicates the type of peak calling to perform        	|
| fastq_1           	| Path to the fastq file of the sample (if paired-end, here goes the forward mate, i.e. R1)                	|
| fastq_2           	| ONLY for paired-end, otherwise leave empty. Path to the fastq file of the reverse mate (i.e. R2)         	|

For the input samples, leave empty the values of the all the columns except for sample, replicate and fastq path(s).

#### Example 1 (single end)

|sample           |replicate|antibody|control        |control_replicate|peak_type|fastq_1                                               |fastq_2|
|-----------------|---------|--------|---------------|-----------------|---------|------------------------------------------------------|-------|
|H3K4me3_untreated|1        |H3K4me3 |Input_untreated|1                |narrow   |fastq/H3K4me3_untreated-1_L1.fastq.gz    |       |
|H3K4me3_untreated|1        |H3K4me3 |Input_untreated|1                |narrow   |fastq/H3K4me3_untreated-1_L2.fastq.gz    |       |
|Input_untreated  |1        |        |               |                 |         |fastq/Input-untreated-1_fastq.gz|       |


> **_⚠️ NOTE:_**  If your sample has **multiple lanes**, you can simple add a new row with the same values in all the columns except for fastq_1 (and fastq_2 if PE). In the table above, H3K4me3_untreated has two lanes

#### Example 2 (paired end)

|sample           |replicate|antibody|control        |control_replicate|peak_type|fastq_1                                               |fastq_2                              |
|-----------------|---------|--------|---------------|-----------------|---------|------------------------------------------------------|-------------------------------------|
|H3K9me2_untreated|1        |H3K9me2 |Input_untreated|1                |very-broad|fastq/H3K9me2_untreated-1_R1.fastq.gz                 |fastq/H3K9me2_untreated-1_R2.fastq.gz|
|H3K9me2_untreated|2        |H3K9me2 |Input_untreated|1                |very-broad|fastq/H3K9me2_untreated-2_R1.fastq.gz                 |fastq/H3K9me2_untreated-2_R2.fastq.gz|
|H3K9me2_EGF      |1        |H3K9me2 |Input_EGF      |1                |very-broad|fastq/H3K9me2_EGF-1_R1.fastq.gz                       |fastq/H3K9me2_EGF-1_R2.fastq.gz      |
|H3K9me2_EGF      |2        |H3K9me2 |Input_EGF      |1                |very-broad|fastq/H3K9me2_EGF-2_R1.fastq.gz                       |fastq/H3K9me2_EGF-2_R2.fastq.gz      |
|Input_untreated  |1        |        |               |                 |         |fastq/Input-untreated-1_R1.fastq.gz                   |fastq/Input-untreated-1_R2.fastq.gz  |
|Input_EGF        |1        |        |               |                 |         |fastq/Input-EGF-1_R1.fastq.gz                         |fastq/Input-EGF-1_R2.fastq.gz        |

> **_⚠️ NOTE:_**  In this case, we have two replicates per condition (untreated and EGF) and the samples are paired-end. However, **mixed situations (some single and some paired-end samples) are also accepted by the pipeline.**

### 2. **Config file**

The last step before running the workflow is to adjust the parameters in the config file (```config/config.yaml```). The file is written in YAML (Yet Another Markup Language), which is a human-readable data serialization format. It contains key-value pairs that can be nested to multiple leves.

#### *Reference and exogenous (spike-in) genomes*

To execute the pipeline, it's essential to specify both *endogenous* and *exogenous* species in the assembly field; for example, use Drosophila (dm16) as the exogenous and Human (hg38) as the endogenous species. You can find the the genome assembly on the [UCSC Genome Browser](https://genome-euro.ucsc.edu/cgi-bin/hgGateway).

If a bowtie2 genome index is already available for the merged genomes (e.g. hg38 + dm16), you should input the path (ending with the index files prefix) in the 'resources' section of the pipeline configuration. This setup ensures proper alignment and processing of your genomic data. **_⚠️ NOTE:_** The index must be created with bowtie2 v2.5.3.

```yaml
resources:
    ref:
        index: "/path/to/hg38_dm16_merged.bowtie2.index/indexFilesPrefix"
        # ucsc genome name (e.g. hg38, mm10, etc)
        assembly: hg38
        #blacklist regions 
        blacklist: ".test/data/hg38-blacklist.v2.bed"

    ref_spike:
        # ucsc genome name (e.g. dm6, mm10, etc)
        spike_assembly: dm6
```

If you don't have the bowtie2 index readily available, the pipeline will generate it for you. To do so, leave empty the index field in the resources section (see below):

```yaml
resources:
    ref:
        index: ""
        # ucsc genome name (e.g. hg38, mm10, etc)
        assembly: hg38
        #blacklist regions 
        blacklist: ".test/data/hg38-blacklist.v2.bed"

    ref_spike:
        # ucsc genome name (e.g. hg38, mm10, etc)
        spike_assembly: dm6
```

> **_⚠️ NOTE:_**  For the endogenous genome,  it's important to also include the path to blacklisted regions.  These regions, often associated with sequencing artifacts or other anomalies, can be downloaded from the Boyle Lab's Blacklist repository on GitHub. You can access these blacklisted region files [here](https://github.com/Boyle-Lab/Blacklist/tree/master/lists)


#### *Normalization*

In this field you can choose the type of normalization to perform on the samples. The available options are:

- **RAW**: This is a RPM normalization, i.e. it normalizes the read counts to the total number of reads in a sample, measured per million reads. This method is straightforward but does not account for spike-in. 

- **Orlando**: Spike-in normalization as described in [Orlando et al 2014](https://pubmed.ncbi.nlm.nih.gov/25437568/). Also reffered as Reference-adjusted Reads Per Million (RRPM). It does not incorporate input data in the normalization process.

- **RX-Input** (default): RX-Input is a modified version of the Orlando normalization that accounts for the total number of reads mapped to the spike-in in both the ChIP and input samples. This approach allows for more accurate normalization by accounting for variations in both immunoprecipitation efficiency and background noise (as represented by the input). See [Fursova et al 2019](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6561741/#bib42) for further details.

- **Downsampling**: The sample with the minimum umber of spike-in reads can be used as the reference. Sample reads from all other samples can be downsampled to the same level as this reference sample. This approach is applicable to datasets where the numbers of reads are similar.

- **Median Normalization**: Normalize to the median. All samples can be normalized to the median value of spike-in reads. This method is not suited for integrating datasets from different sources.

```yaml
normalization_type: "Orlando"
```

#### *Differential Peak analysis*

SpikeFlow allows you to perform differential peaks analysis. In this case, the grouping variable for the samples will be extracted from the sample name in the *sample_sheet.csv* (after the last '\_'). Also, if ```perform_diff_analysis: true```, you will need to specify the contrasts (per antibody), meaning the groups that you want to compare. Please also specify the log2 fold change (log2FCcutoff) and adjusted p-value (padjust) thresholds for differential analysis. 

> **_⚠️ NOTE:_**  Ensure that the group names for the differential peaks analysis and the contrast names do not contain any additional underscores ('\_'), and that the antibody names do not contain any underscores ('\_'). 

When differential peak analysis is enabled, SpikeFlow will create a consensus peak set per antibody and count reads on those peaks. The default behavior to build the consensus regions is to use all the peaks from all the samples (i.e., minNumSamples: 0). However, you can change this to specify the minimum number of samples a peak should be present in to be kept for the consensus peak set (minNumSamples).

> **_⚠️ NOTE:_**  If ```useSpikeinCalledPeaks: true```, spike-normalized peak calling will be executed in addition to the standard peak calling. The resulting regions from the spike-normalized peak calling will be used for consensus peak set generation and differential analysis.

```yaml

diffPeakAnalysis:
  perform_diff_analysis: true
  contrasts:
    H3K4me3:
      - "EGF_vs_untreated"
  padjust: 0.01
  log2FCcutoff: 1.5
  minNumSamples: 1
  useSpikeinCalledPeaks: false
```

#### *Required options*

When configuring your pipeline based on the chosen reference/endogenous genome (like mm10 or hg38), two essential options need to be set:

- **effective genome length**: This is required by deeptools to generate the bigWig files. The value of this parameter is used by the program to adjust the mappable portion of the genome, ensuring that the read densities represented in the BigWig files accurately reflect the underlying biological reality. You can find the possible values for this parameter in the deeptools [documentation](https://deeptools.readthedocs.io/en/latest/content/feature/effectiveGenomeSize.html).

- **chrom sizes**: To achieve accurate peak calling, it's important to use the correct chromosome sizes file. The supported genomes' chromosome sizes are available under ```resources/chrom_size```.  **Make sure to select the file that corresponds to your chosen genome**.


#### *Other (optional) parameters*

-  To direct Snakemake to save all outputs in a specific directory, add the desired path in the config file: ```output_path: "path/to/directory"```.

- While splitting the BAM file into two separate ones (one endogenous and one spike-in), reads with a mapping quality below 8 are discarded. You can adjust this behavior using the bowtie2 ```map_quality``` field. If no filtering is needed, set this value to 0; otherwise, adjust it from 0 to 30 as needed. For more information on Bowtie2 MAPQ scores, see [here](http://biofinysics.blogspot.com/2014/05/how-does-bowtie2-assign-mapq-scores.html).

- **Broad Peak Calling:** For samples requiring broad peak calling, adjust the effective genome fraction as per the guidelines on this [page]( https://github.com/biocore-ntnu/epic2/blob/master/epic2/effective_sizes/hg38_50.txt). The *'effective genome size'* mentioned on the GitHub page depends on the read length of your samples.

- **Very Broad Peak Callling:** If you have samples that will undergo very-broad peak calling, please check the log files produced by EDD. This because the tool might fail if it can not accurately estimate the parameters for the peak calling. In this case, you can tweak the parameters in the EDD config file, which is in the config directory (```config/edd_parameters.conf```). For more information about EDD parameters tuning see the [documentation](https://github.com/CollasLab/edd).

- **Trimming Option:** Trimming can be skipped by setting the respective flag to false.

- **P-Value Adjustment for Peak Calling:** Modify the q-values for peak calling in the config file. This applies to different peak calling methods: narrow (macs2), broad (epic2), or very-broad (edd).

- **Peak Annotation Threshold:** The default setting annotates a peak within ±2500 bp around the promoter region.

<a name="run"></a>
## Run the workflow

To execute the pipeline, make sure to be in the main  **Snakemake working directory**, which includes subfolders like 'workflow', 'resources', and 'config'. 

The workflow can be operated in two ways: using Conda alone, or a combination of Conda and Singularity (**recommended**). 
After obtaining a copy of the workflow on your machine, you can verify its proper functioning by executing one of the two commands below. 
The ```config``` and ```sample_sheet``` files come pre-configured for a test run.

#### Conda and Singularity (recommended)

```bash
snakemake --cores 10 --software-deployment-method conda apptainer
```

First, the singularity container will be pulled from DockerHub and then the workflow will be executed. To install sigularity, see the [installation](#install) section.

#### Conda only

```bash
snakemake --cores 10 --software-deployment-method conda
```
This will install all the required conda envs (it might take a while, just for the first execution).

#### Snakemake flags

- ```--cores```: adjust this number (here set to 10) based on your machine configuration
- ```-n```: add this flag  to the command line for a "dry run," which allows Snakemake to display the rules that it would execute, without actually running them. 
- ```--singularity-args "-B /shares,/home -e"```: only with ```--software-deployment-method conda apptainer``` and if you are running SpikeFlow from a server that mounts /shares and /home disks (where you have your working dir and files).

To execute the pipeline on a HPC cluster, please follow [these guidelines](https://snakemake.readthedocs.io/en/stable/tutorial/additional_features.html#cluster-execution).


<a name="output"></a>
## Output files


All the outputs of the workflow are stored in the ```results``` folder. Additionally, in case of any errors during the workflow execution, the log files are stored within the ```results/logs``` directory.


The main outputs of the workflow are:

- **MultiQC Report** 

    - If the differential peaks analysis was activated, you will find scatter plots/volcano and PCA plots in the report. 
    - Peak Calling Data: Displays the number of peaks called per sample for each method (MACS2, EPIC2, EDD).
    - Peaks annotation
    - Reads Table: Per sample reference and spike-in calculated with the normalisation set by the user.
    - Basic QC with FastQC: Evaluates basic quality metrics of the sequencing data.
    - Phantom Peak Qual Tools: Provides NSC and RSC values, indicating the quality and reproducibility of ChIP samples. NSC measures signal-to-noise ratio, while RSC assesses enrichment strength.
    - Fingerprint Plots: Visual representation of the sample quality, showing how reads are distributed across the genome.

     ```results/QC/multiqc/multiqc_report.html```

- **Peaks Differential Analysis**
    - In this folder, you will find the differential peak regions and the volcano/scatter/pca plots for each antibody and contrast.

    ``results/differentialAnalysis``

    If spike-in normalised peak calling was activated, you will find the results of the differential analysis in:

    ``results/differentialAnalysis/NormalisedPeaks``

- **Normalized BigWig Files**: 
    - Essential for visualizing read distribution and creating detailed heatmaps.

    ```results/bigWigs/```

-  **Peak Files and Annotation**:
    - Provides called peaks for each peak calling method.  Consensus regions bed files are in ```/results/peakCalling/mergedPeaks```
    - Peak annotation using ChIPseeker, resulting in two files for promoter and distal peaks for each sample  ```/results/peakCalling/peakAnnot```

    - Standard peak calling: ```/results/peakCalling/``` 

    - Spike-in normalised peak calling: ```/results/peakCallingNorm/``` 





<a name="troubleshooting"></a>
## Troubleshooting

1. When you run SpikeFlow with Singularity ( ```--use-singularity```), you might get an error if you set the  ```-n``` flag. This happens ONLY at the first execution of the workflow. Remove the flag and it should work.

2. The ``` --use-singularity```  option temporary requires about 7 GB of disk space to build the image from Docker Hub. If your ```/tmp``` directory is full, you'll encounter a ```No space left on device``` error. To avoid this, change the Singularity temp directory to a different disk by setting the ```SINGULARITY_TMPDIR``` environment variable. More details are available in the [Singularity guide on temporary folders](https://docs.sylabs.io/guides/latest/user-guide/build_env.html#temporary-folders).

3. In case of errors during the execution, please make sure to check the log files of the failing snakemake rule in the log folders

4. For the R scripts execution in SpikeFlow, the env variable R_LIBS_SITE has to be empty otherwise snakemake will look in that folder for R libraries. To avoid this you can use ```unset R_LIBS_SITE```. 

<a name="citation"></a>
## Citation

If you use this workflow in a paper, don't forget to give credits to the authors by citing the URL of this (original) repository:
https://github.com/DavideBrex/SpikeFlow

**Author**:
- Davide Bressan ([@DavideBrex](https://twitter.com/BrexDavide))

