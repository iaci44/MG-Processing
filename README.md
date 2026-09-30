# Shotgun Metagenomics Processing Pipeline

A reproducible Linux pipeline for shotgun metagenomic data processing.

This workflow automates the main steps required for shotgun metagenomic analysis:

- Quality control of raw FASTQ reads
- Optional trimming of low-quality reads
- Host DNA removal
- Taxonomic profiling using MetaPhlAn
- Functional profiling using HUMAnN
- Merging and normalization of functional results

The pipeline is designed to separate:

- software environments
- reference databases
- individual analysis projects

allowing multiple projects to be analyzed using the same installed tools and databases.

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
- Conda / Miniconda / Mambaforge
- Sufficient computational resources


Recommended resources:

- 12 CPU cores
- 50+ GB RAM
- Large storage capacity (>100 GB recommended)

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
│   └── config.sh
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

---

## 2. Install environments and databases

Run:

```bash
bash install.sh PROJECT_NAME
```

Example:

```bash
bash install.sh TEST_pipeline
```

If no project name is specified:

```bash
bash install.sh
```

the default project name is:

```
MG_Project
```

The installation script performs:

- creation of Conda environments
- installation of required software
- download of reference databases
- HUMAnN configuration
- creation of project folders

---

# Software environments

The pipeline uses two independent Conda environments.

## MG-Shotgun

Contains:

- MetaPhlAn
- Bowtie2
- FastQC
- fastp
- samtools


## HUMAnN-func

Contains:

- HUMAnN 3.9
- Python 3.9
- DIAMOND
- MetaPhlAn dependencies


HUMAnN is installed using:

```
Python 3.9 + pip
```

to avoid incompatible Python builds from Conda packages.

---

# Database management

Reference databases are installed once and reused across multiple projects.

Default location:

```
~/databases/
```

Structure:

```
databases/

├── metaphlan/
├── chocophlan/
├── uniref/
├── utility_mapping/
└── host_human/
```

After the first installation, new projects do not require database re-downloads.

---

# Reference databases

The installation downloads:


## MetaPhlAn database

Used for taxonomic profiling.

Location:

```
~/databases/metaphlan/
```


## ChocoPhlAn database

Used by HUMAnN nucleotide mapping.

Location:

```
~/databases/chocophlan/
```


## UniRef90 database

Used by HUMAnN protein alignment.

Location:

```
~/databases/uniref/
```


## Utility mapping database

Used for HUMAnN pathway reconstruction.

Location:

```
~/databases/utility_mapping/
```

---

# Human genome database

The pipeline requires a Bowtie2 index of the human genome for host DNA removal.

This database is not downloaded automatically.

Expected location:

```
~/databases/host_human/
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

The path can be modified in:

```
config/config.sh
```

---

# Project setup

Each analysis is stored in an independent project folder.

Example:

```bash
bash MG_pipeline.sh My_Project
```

The pipeline automatically creates:

```
$HOME/My_Project/
```

with:

```
My_Project/

├── raw_fastq/
├── metadata/
├── results/
├── logs/
└── scripts/
```

Different projects can share the same software environments and databases.

Example:

```
~/TEST_pipeline

~/epilepsy_project

~/new_dataset
```

---

# Input data

The pipeline requires paired-end shotgun metagenomic FASTQ files.

FASTQ files must be stored in:

```
My_Project/raw_fastq/
```

Expected naming convention:

```
sample01.1.fastq.gz
sample01.2.fastq.gz

sample02.1.fastq.gz
sample02.2.fastq.gz
```

where:

- `.1.fastq.gz` corresponds to forward reads (R1)
- `.2.fastq.gz` corresponds to reverse reads (R2)


Example:

```
raw_fastq/

├── mgshot_S16781Nr1.1.fastq.gz
├── mgshot_S16781Nr1.2.fastq.gz
├── mgshot_S16781Nr2.1.fastq.gz
└── mgshot_S16781Nr2.2.fastq.gz
```

The pipeline automatically detects samples from:

```
*.1.fastq.gz
```

and creates:

```
metadata/samples.txt
```

---

# Running the pipeline

Launch the complete workflow:

```bash
bash MG_pipeline.sh My_Project
```

For long analyses it is recommended to use:

```bash
screen
```

Example:

```bash
screen -S metagenomics_run

bash MG_pipeline.sh My_Project
```

Detach from screen:

```
CTRL+A
D
```

Reconnect:

```bash
screen -r metagenomics_run
```

---

# Pipeline steps

## 1. Quality control

Raw reads are evaluated using:

- FastQC

Optional trimming can be enabled using:

- fastp


Output:

```
results/01_qc/
```

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

- MetaPhlAn 4


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

- HUMAnN 3.9


Output:

```
results/04_humann3/
```

---

# Monitoring HUMAnN

HUMAnN analyses can require several hours depending on dataset size.

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

If a HUMAnN sample fails:

```bash
bash restart_humann.sh SAMPLE_NAME
```

Completed samples are automatically skipped.

---

# Troubleshooting

## Conda activation error

If:

```
CondaError: Run 'conda init' before 'conda activate'
```

appears, scripts must load Conda before activating environments:

```bash
source ~/mambaforge/etc/profile.d/conda.sh
```

---

## Bowtie2 not found

Check:

```bash
which bowtie2
```

The output should point to the Conda environment.

Example:

```
~/mambaforge/envs/MG-Shotgun/bin/bowtie2
```

---

## MetaPhlAn database not found

Check:

```bash
ls ~/databases/metaphlan
```

A complete MetaPhlAn database should contain Bowtie2 index files:

```
*.bt2l
```

---

## DIAMOND bus error

Possible causes:

- insufficient memory
- database stored on unsupported filesystem


Keep databases on a Linux filesystem.

Avoid using mounted Windows drives such as:

```
/mnt/
```

---

# Output summary

## Taxonomic results

```
My_Project/results/03_metaphlan/
```


## Functional results

```
My_Project/results/04_humann3/
```


The resulting tables can be used for downstream microbiome statistical analyses.