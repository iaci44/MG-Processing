# Shotgun Metagenomics Processing Pipeline

A reproducible Linux pipeline for shotgun metagenomic data processing.

This workflow automates the main steps required for shotgun metagenomic analysis:

- Quality control of raw FASTQ reads
- Optional trimming of low-quality reads
- Host DNA removal
- Taxonomic profiling using MetaPhlAn
- Functional profiling using HUMAnN
- Merging and normalization of functional results


---

# Pipeline overview

```
Raw FASTQ files
        |
        v
Quality control
(FastQC / optional fastp)
        |
        v
Host DNA removal
(Bowtie2)
        |
        v
Taxonomic profiling
(MetaPhlAn)
        |
        v
Functional profiling
(HUMAnN)
        |
        v
Merged results
```


---

# Requirements

The pipeline requires:

- Linux operating system
- Bash shell
- Conda / Miniconda
- Sufficient computational resources


Recommended resources:

- 12 CPU cores
- 50+ GB RAM
- Large storage capacity for databases


---

# Repository structure

```
MG-Processing/

├── install.sh
├── MG_pipeline.sh
├── monitor_humann.sh
├── merge_results.sh
├── restart_humann.sh
│
├── config/
│   ├── config.sh
│   └── wslconfig_example
│
└── README.md
```


---

# Installation

## 1. Clone repository

```bash
git clone https://github.com/iaci44/MG-Processing.git

cd MG-Processing
```


## 2. Install environments and databases

Run:

```bash
bash install.sh
```

The installation script creates two Conda environments:

- `MG-Shotgun`
- `HUMAnN-func`

and installs the required software:

- MetaPhlAn
- HUMAnN
- Bowtie2
- FastQC
- fastp
- DIAMOND


The script also downloads:

- MetaPhlAn database
- ChocoPhlAn database
- UniRef90 database
- Utility mapping database


---

# Configuration

Pipeline parameters are stored in:

```
config/config.sh
```

The configuration file contains:

- database paths
- computational resources
- software parameters


Example:

```bash
THREADS=12
```

Modify these parameters according to the available system resources.

Database paths are defined in:

```bash
HUMAN_DB
METAPHLAN_DB
CHOCOPHLAN_DB
UNIREF_DB
UTILITY_DB
```


---

# Project setup

The project name is provided when launching the pipeline.

Example:

```bash
bash MG_pipeline.sh My_Project
```

The pipeline will automatically create and use the following project directory:

```
$HOME/My_Project/
```

with the structure:

```
My_Project/

├── raw_fastq/
├── metadata/
├── results/
└── logs/
```


This allows multiple datasets to be analyzed independently without modifying the pipeline code.


---

# Human genome database

The pipeline requires a Bowtie2 index of the human genome for host read removal.

This database is **not downloaded automatically**.

The expected location is:

```
~/databases/host_human/human_GRCh38
```

The path can be modified in:

```
config/config.sh
```

The folder should contain Bowtie2 index files:

```
human_GRCh38.1.bt2
human_GRCh38.2.bt2
human_GRCh38.3.bt2
human_GRCh38.4.bt2
human_GRCh38.rev.1.bt2
human_GRCh38.rev.2.bt2
```


---

# Input data

The pipeline requires paired-end shotgun metagenomic FASTQ files.

FASTQ files must be stored in:

```
My_Project/raw_fastq/
```

The expected naming convention is:

```
sample01.1.fastq.gz
sample01.2.fastq.gz

sample02.1.fastq.gz
sample02.2.fastq.gz
```

where:

- `.1.fastq.gz` corresponds to forward reads (R1)
- `.2.fastq.gz` corresponds to reverse reads (R2)


The pipeline automatically detects samples from files ending with:

```
.1.fastq.gz
```

and creates:

```
metadata/samples.txt
```

containing the sample names used throughout the workflow.


Example:

```
raw_fastq/

├── sample01.1.fastq.gz
├── sample01.2.fastq.gz
├── sample02.1.fastq.gz
└── sample02.2.fastq.gz
```


---

# Running the pipeline

Launch the complete workflow by specifying the project name:

```bash
bash MG_pipeline.sh My_Project
```


For long analyses (especially HUMAnN), run in background:

```bash
nohup bash MG_pipeline.sh My_Project > logs/pipeline.log 2>&1 &
```


Save the process ID:

```bash
echo $! > logs/pipeline.pid
```


---

# Pipeline steps

## 1. Quality control

Raw reads are evaluated using:

- FastQC

Optional trimming can be enabled using:

- fastp


---

## 2. Host DNA removal

Human reads are removed using:

- Bowtie2


Output:

```
results/02_host_removed/
```


---

## 3. Taxonomic profiling

Taxonomic composition is estimated using:

- MetaPhlAn


Output:

```
results/03_metaphlan/
```


Final taxonomy table:

```
results/03_metaphlan/merged_abundance_table.tsv
```


---

## 4. Functional profiling

Functional characterization is performed using:

- HUMAnN


Output:

```
results/04_humann3/
```


---

# Monitoring HUMAnN

HUMAnN analyses can require several hours or days depending on dataset size.

To monitor a running analysis:

```bash
bash monitor_humann.sh
```

The monitoring script reports:

- running processes
- log progress
- completed samples
- pipeline status


---

# Merge results

After HUMAnN completion:

```bash
bash merge_results.sh
```

The final functional outputs include:

```
results/04_humann3/merged/
```

with:

- gene families
- pathway abundance
- pathway coverage
- CPM normalized tables


---

# Restart interrupted runs

If a HUMAnN sample gets stuck:

```bash
bash restart_humann.sh SAMPLE_NAME
```

Completed samples are automatically skipped during restart.


---

# Troubleshooting

## Bowtie2 not found or wrong version

Check:

```bash
which bowtie2
```

The output should point to the Conda environment.

Example:

```
~/miniconda3/envs/MG-Shotgun/bin/bowtie2
```


---

## DIAMOND bus error

Possible causes:

- insufficient memory
- databases stored on unsupported filesystem


Keep databases on a Linux filesystem (ext4).

Avoid running databases directly from mounted Windows drives such as:

```
/mnt/
```

when using WSL2.


---

## Multiple HUMAnN processes

Check:

```bash
pgrep -c -f humann.sh
```

If multiple processes are running, stop duplicated jobs before restarting.


---

## Long overnight runs

For long analyses:

- use `nohup`
- use `tmux`
- disable system sleep


---

# WSL2 users

If running the pipeline through WSL2, configure resources using:

```
.wslconfig
```

Example configuration:

```ini
[wsl2]

memory=56GB
processors=12
swap=8GB
```

Values should be adapted according to available hardware resources.


After changing the configuration restart WSL:

```bash
wsl --shutdown
```


---

# Output summary

## Taxonomic results

```
results/03_metaphlan/merged_abundance_table.tsv
```


## Functional results

```
results/04_humann3/merged/
```


The resulting tables can be used for downstream microbiome statistical analyses.