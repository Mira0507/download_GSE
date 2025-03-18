import pandas as pd
import subprocess
import os

# Import sampletable
table_path = "sampletable.csv"
sampletable = pd.read_csv(table_path).set_index('samplename', drop=False)
samplenames = list(sampletable.index)

rule all:
    input:
        expand("fastq/{srr}_{sample}_R1.fastq.gz", zip, srr=sampletable["SRR"], sample=samplenames),
        expand("fastq/{srr}_{sample}_R2.fastq.gz", zip, srr=sampletable["SRR"], sample=samplenames)


rule prefetch:
    """
    Downloads SRA accessions
    """
    output:
        temp("{srr}/{srr}.sra")
    threads: 1
    resources:
        mem_mb = 1024 * 20,
        disk_mb = 1024 * 10,
        runtime = 30
    shell:
        # NOTE: `--max-size u` is set to allow unlimited maximum download size.
        # The size is limited to 20G without this parameter. Visit 
        # https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump#check-the-maximum-size-limit-of-the-prefetch-tool
        # for more details.
        """
        prefetch {wildcards.srr} --max-size u
        """

rule fasterq_dump:
    """
    Converts .sra to .fastq
    """
    input:
        "{srr}/{srr}.sra"
    output:
        # NOTE: A single SRA file creates two fastq files
        r1="fastq/{srr}_{sample}_R1.fastq",
        r2="fastq/{srr}_{sample}_R2.fastq"
    threads: 1
    resources:
        mem_mb = 1024 * 20,
        disk_mb = 1024 * 10,
        runtime = 30
    shell:
        # NOTE: The `fasterq-dump` command  works differently
        # from the original `fastq-dump`. Visit
        # https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump#extract-fastq-files-from-sra---accessions
        # for more details.
        """
        fasterq-dump {wildcards.srr} &&
        mv {wildcards.srr}_1.fastq {output.r1} &&
        mv {wildcards.srr}_2.fastq {output.r2}
        """
        # rm -rf {wildcards.srr}

rule compress:
    """
    Compresses FASTQ files
    """
    input:
        "fastq/{srr}_{sample}_{read}.fastq"
    output:
        "fastq/{srr}_{sample}_{read}.fastq.gz"
    threads: 1
    resources:
        mem_mb = 1024 * 20,
        disk_mb = 1024 * 10,
        runtime = 90
    shell: 
        # NOTE: The `gzip` command is single-threaded. There are workarounds
        # if you need a multithreaded decompression. The `-9` parameter was 
        # used for the max level decompression.
        "gzip {input} -9"
