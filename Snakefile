import pandas as pd
import subprocess
import os

# ----------------- for interactive debugging -------------------
# import yaml
# with open("config/multiome-config/config.yaml", 'r') as stream:
#     config = yaml.safe_load(stream)
# ---------------------------------------------------------------


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
        "{srr}/{srr}.sra"
    threads: 1
    resources:
        mem_mb = 1024 * 20,
        disk_mb = 1024 * 10,
        runtime = 30
    shell:
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
        r1="fastq/{srr}_{sample}_R1.fastq",
        r2="fastq/{srr}_{sample}_R2.fastq"
    threads: 1
    resources:
        mem_mb = 1024 * 20,
        disk_mb = 1024 * 10,
        runtime = 30
    shell:
        """
        fasterq-dump {wildcards.srr} &&
        mv {wildcards.srr}_1.fastq {output.r1} &&
        mv {wildcards.srr}_2.fastq {output.r2} &&
        rm -rf {wildcards.srr}
        """
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
        runtime = 60
    shell: 
        "gzip {input} -9"
