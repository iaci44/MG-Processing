# Shotgun Metagenomics Processing Pipeline

A reproducible Linux pipeline for shotgun metagenomic data processing.

This workflow automates the main steps required for shotgun metagenomic
analysis:

-   Quality control of raw FASTQ reads
-   Optional read trimming with `fastp` (currently disabled by default)
-   Human DNA removal with Bowtie2
-   Taxonomic profiling with MetaPhlAn
-   Functional profiling with HUMAnN
-   Merging and CPM normalization of HUMAnN functional results

The workflow is designed to separate:

-   software environments
-   reference databases
-   individual analysis projects

so that multiple projects can use the same installed software and
reference databases.

> **Validated test:** the complete workflow was successfully tested
> end-to-end on two paired-end samples, from raw FASTQ files through
> MetaPhlAn, HUMAnN, merging, and output validation.

------------------------------------------------------------------------

# 1. Pipeline overview

``` text
Raw paired-end FASTQ
        |
        v
Quality control
FastQC
        |
        v
Optional trimming
fastp
(currently disabled)
        |
        v
Human DNA removal
Bowtie2 / GRCh38
        |
        v
Taxonomic profiling
MetaPhlAn 4.2.5
        |
        +--> merged_abundance_table.tsv
        |
        v
Functional profiling
HUMAnN 3.9
        |
        +--> gene families
        +--> pathway abundance
        +--> pathway coverage
        |
        v
merge_results.sh
        |
        +--> merged multicample functional matrices
        +--> CPM-normalized matrices
        +--> stratified / unstratified tables
```

------------------------------------------------------------------------

# 2. Requirements

The pipeline requires:

-   Linux
-   Bash
-   Mambaforge/Conda
-   sufficient CPU, RAM, and storage

Recommended resources:

-   12 CPU cores

-   50+ GB RAM

-   100 GB free storage, depending on the number and size of samples

Large shotgun metagenomic datasets can require substantially more
storage and runtime.

For long-running analyses on a remote server, use `screen` or `tmux`.

------------------------------------------------------------------------

# 3. Repository structure

``` text
MG-Processing/

├── install.sh
├── MG_pipeline.sh
├── merge_results.sh
├── monitor_humann.sh
├── restart_humann.sh
│
├── config/
│   └── config.sh
│
└── README.md
```

Main scripts:

  -----------------------------------------------------------------------
  Script                              Purpose
  ----------------------------------- -----------------------------------
  `install.sh`                        Creates/sets up the software
                                      environments and reference
                                      databases

  `MG_pipeline.sh`                    Runs the main per-project
                                      processing workflow

  `merge_results.sh`                  Merges HUMAnN per-sample outputs
                                      into multicample matrices

  `monitor_humann.sh`                 Monitors HUMAnN progress

  `restart_humann.sh`                 Restarts a failed/interrupted
                                      HUMAnN sample
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 4. Installation

## 4.1 Clone the repository

``` bash
git clone https://github.com/iaci44/MG-Processing.git
cd MG-Processing
```

## 4.2 Install the software environments and databases

Run the installation script once on the server:

``` bash
bash install.sh
```

The installation script is intended to create/configure:

-   `MG-Shotgun`
-   `HUMAnN-func`
-   MetaPhlAn reference databases
-   ChocoPhlAn
-   UniRef90
-   HUMAnN utility mapping
-   the human GRCh38 host-removal database path

The installation is server-level: once the environments and databases
are available, they can be reused for multiple projects.

### Important

`install.sh` protects the Turing `base` environment and is designed not
to modify it. It should be run outside the active `base` environment.

For example:

``` bash
conda deactivate
bash install.sh
```

The main analysis script is different: `MG_pipeline.sh` calls the
executables directly from the two dedicated environments and does
**not** activate Conda environments, run `conda`, run `mamba`, or modify
`.bashrc`.

------------------------------------------------------------------------

# 5. Software environments

The validated workflow uses two separate Conda environments.

## 5.1 MG-Shotgun

Used for taxonomic profiling and preprocessing.

Main tools:

-   MetaPhlAn **4.2.5**
-   Bowtie2
-   FastQC
-   fastp
-   samtools
-   `merge_metaphlan_tables.py`

The standalone MetaPhlAn step uses the MetaPhlAn 4.2 interface:

``` text
--db_dir
--mapout
```

## 5.2 HUMAnN-func

Used for functional profiling.

Validated versions:

-   HUMAnN **3.9**
-   MetaPhlAn **4.1.1**
-   DIAMOND
-   Bowtie2
-   HUMAnN database utilities

### Why are there two MetaPhlAn versions?

This is intentional.

The pipeline keeps the environments separate because the standalone
taxonomic workflow uses MetaPhlAn 4.2.5, whereas HUMAnN 3.9 requires the
older MetaPhlAn interface used by the HUMAnN functional environment.

Therefore:

``` text
MG-Shotgun
└── MetaPhlAn 4.2.5
    └── taxonomy

HUMAnN-func
├── HUMAnN 3.9
└── MetaPhlAn 4.1.1
    └── functional profiling
```

Do not replace MetaPhlAn 4.1.1 inside `HUMAnN-func` with 4.2.x without
changing the HUMAnN workflow and compatibility configuration.

------------------------------------------------------------------------

# 6. Manual environment activation

The main pipeline does not require manual environment activation.

Manual activation is useful only for testing/debugging individual
programs.

## Taxonomic environment

``` bash
conda activate MG-Shotgun
```

Examples:

``` bash
metaphlan --version
bowtie2 --version
fastqc --version
fastp --version
```

## Functional environment

``` bash
conda activate HUMAnN-func
```

Examples:

``` bash
humann --version
metaphlan --version
diamond version
```

The validated HUMAnN environment should report:

``` text
HUMAnN 3.9
MetaPhlAn 4.1.1
```

------------------------------------------------------------------------

# 7. Reference databases

Reference databases are installed once and reused across projects.

Default root:

``` text
~/databases/
```

Expected logical structure:

``` text
~/databases/

├── metaphlan/
├── metaphlan_humann/
├── chocophlan/
├── uniref/
├── utility_mapping/
└── host_human/
```

The database directories used by the scripts are defined in:

``` text
config/config.sh
```

## 7.1 MetaPhlAn database

Used by the standalone MetaPhlAn 4.2.5 taxonomic step.

``` text
~/databases/metaphlan/
```

## 7.2 HUMAnN MetaPhlAn database

HUMAnN uses a separate MetaPhlAn database from the standalone MetaPhlAn
step.

Validated index:

``` text
mpa_vJun23_CHOCOPhlAnSGB_202403
```

Logical location:

``` text
~/databases/metaphlan_humann/
```

This separation is intentional because the HUMAnN 3.9 environment uses
MetaPhlAn 4.1.1.

## 7.3 ChocoPhlAn

Used by HUMAnN for nucleotide-level functional mapping.

Validated database version:

``` text
v201901_v31
```

The actual configured path must point to the directory containing the
ChocoPhlAn database files.

## 7.4 UniRef90

Used by HUMAnN for translated/protein-level functional alignment.

Validated database:

``` text
UniRef90 201901b
```

The actual configured path must point to the directory containing:

``` text
uniref90_201901b_full.dmnd
```

## 7.5 Utility mapping

Used by HUMAnN for functional/pathway reconstruction.

The configured path must point to the directory containing the HUMAnN
utility mapping files.

------------------------------------------------------------------------

# 8. Human reference genome

Host DNA removal requires a Bowtie2 index of the human GRCh38 reference
genome.

Expected logical location:

``` text
~/databases/host_human/
```

The index should contain files equivalent to:

``` text
human_GRCh38.1.bt2
human_GRCh38.2.bt2
human_GRCh38.3.bt2
human_GRCh38.4.bt2
human_GRCh38.rev.1.bt2
human_GRCh38.rev.2.bt2
```

The exact prefix/path is defined in:

``` text
config/config.sh
```

The pipeline uses Bowtie2 with:

``` text
--very-sensitive
```

and retains the non-human paired reads for downstream processing.

------------------------------------------------------------------------

# 9. Project structure

Each analysis is stored independently.

For example:

``` text
~/TEST_pipeline/
~/epilepsy_project/
~/new_dataset/
```

A project contains its own input data, metadata, logs, and processing
results.

Example:

``` text
TEST_pipeline/

├── raw_fastq/
├── metadata/
├── results/
│   ├── 01_qc/
│   ├── 02_host_removed/
│   ├── 03_metaphlan/
│   └── 04_humann3/
└── logs/
```

Software environments and reference databases remain shared.

------------------------------------------------------------------------

# 10. Input FASTQ files

The pipeline expects paired-end shotgun metagenomic FASTQ files.

Place them in:

``` text
PROJECT_NAME/raw_fastq/
```

Required naming convention:

``` text
sample01.1.fastq.gz
sample01.2.fastq.gz

sample02.1.fastq.gz
sample02.2.fastq.gz
```

where:

-   `.1.fastq.gz` = forward reads (R1)
-   `.2.fastq.gz` = reverse reads (R2)

Example:

``` text
raw_fastq/

├── mgshot_S16781Nr1.1.fastq.gz
├── mgshot_S16781Nr1.2.fastq.gz
├── mgshot_S16781Nr2.1.fastq.gz
└── mgshot_S16781Nr2.2.fastq.gz
```

The pipeline detects samples from:

``` text
*.1.fastq.gz
```

and automatically creates:

``` text
metadata/samples.txt
```

The corresponding `.2.fastq.gz` file must exist for every detected
sample.

------------------------------------------------------------------------

# 11. Running the pipeline

Once the project directory is prepared, run:

``` bash
cd /home/biox/MG-Processing
bash MG_pipeline.sh TEST_pipeline
```

For another project:

``` bash
bash MG_pipeline.sh epilepsy_project
```

The script expects the project directory at:

``` text
$HOME/PROJECT_NAME/
```

Therefore:

``` bash
bash MG_pipeline.sh TEST_pipeline
```

uses:

``` text
/home/biox/TEST_pipeline/
```

on the Turing server.

------------------------------------------------------------------------

# 12. Recommended use of screen

Shotgun metagenomic processing can take many hours.

Start a detached-capable screen session:

``` bash
screen -S metagenomics_run
```

Run the pipeline:

``` bash
cd /home/biox/MG-Processing
bash MG_pipeline.sh TEST_pipeline
```

Detach without stopping the pipeline:

``` text
Ctrl+A
D
```

List screens:

``` bash
screen -ls
```

Reconnect:

``` bash
screen -r metagenomics_run
```

If the screen is already attached elsewhere:

``` bash
screen -d -r metagenomics_run
```

Do not use `Ctrl+C` if you want the pipeline to continue running.

------------------------------------------------------------------------

# 13. Pipeline steps and outputs

## Step 1 --- Quality control

FastQC is run on all raw FASTQ files.

Output:

``` text
PROJECT_NAME/results/01_qc/
```

Typical files:

``` text
sample.1_fastqc.html
sample.1_fastqc.zip
sample.2_fastqc.html
sample.2_fastqc.zip
```

### Trimming status

The script contains an optional `fastp` block, but:

``` bash
RUN_TRIMMING=false
```

by default.

The validated workflow therefore does **not** trim the reads.

Important: the current downstream host-removal step uses the original
files in `raw_fastq/`. Therefore, simply changing `RUN_TRIMMING=true` is
not sufficient to guarantee that trimmed reads are propagated through
the complete workflow.

If trimming is required for a future project, the pipeline should first
be modified so that the trimmed FASTQ files become the explicit
downstream input.

------------------------------------------------------------------------

# 14. Step 2 --- Human DNA removal

Host removal is performed with Bowtie2 against GRCh38.

Input:

``` text
PROJECT_NAME/raw_fastq/
```

Output:

``` text
PROJECT_NAME/results/02_host_removed/
```

For each sample:

``` text
sample_clean.1.fastq.gz
sample_clean.2.fastq.gz
```

These non-human paired reads are then used by both MetaPhlAn and HUMAnN.

------------------------------------------------------------------------

# 15. Step 3 --- Taxonomic profiling with MetaPhlAn

The standalone taxonomic workflow uses:

``` text
MetaPhlAn 4.2.5
```

and the MetaPhlAn database configured in:

``` text
~/databases/metaphlan/
```

The script uses the MetaPhlAn 4.2 interface:

``` text
--db_dir
--mapout
```

For every sample, the pipeline creates:

``` text
sample_profile.tsv
sample_bt2.bz2
```

in:

``` text
PROJECT_NAME/results/03_metaphlan/
```

The individual profiles are then merged automatically by:

``` text
merge_metaphlan_tables.py
```

Final taxonomic matrix:

``` text
PROJECT_NAME/results/03_metaphlan/merged_abundance_table.tsv
```

Therefore, unlike HUMAnN, **MetaPhlAn merging is already included in
`MG_pipeline.sh`.**

------------------------------------------------------------------------

# 16. Step 4 --- Functional profiling with HUMAnN

Functional profiling is performed with:

``` text
HUMAnN 3.9
```

using the dedicated:

``` text
HUMAnN-func
```

environment.

HUMAnN internally uses MetaPhlAn 4.1.1 and the dedicated HUMAnN
MetaPhlAn database.

For each sample, outputs are stored separately:

``` text
PROJECT_NAME/results/04_humann3/per_sample/SAMPLE_NAME/
```

The three principal output files are:

``` text
SAMPLE_NAME_genefamilies.tsv
SAMPLE_NAME_pathabundance.tsv
SAMPLE_NAME_pathcoverage.tsv
```

### Gene families

`*_genefamilies.tsv` contains functional gene-family abundances,
including UniRef90 identifiers and taxonomically stratified entries.

### Pathway abundance

`*_pathabundance.tsv` contains reconstructed pathway abundances.

### Pathway coverage

`*_pathcoverage.tsv` contains pathway coverage values.

Coverage is not a CPM abundance measure and should not be normalized as
CPM.

------------------------------------------------------------------------

# 17. HUMAnN processing strategy

The pipeline creates a temporary interleaved FASTQ for each sample:

``` text
SAMPLE_NAME_concat.fastq.gz
```

HUMAnN processes this file and writes the results into:

``` text
results/04_humann3/per_sample/SAMPLE_NAME/
```

The temporary concatenated FASTQ is removed after successful HUMAnN
completion.

The pipeline also writes a sample-specific HUMAnN log:

``` text
results/04_humann3/logs/SAMPLE_NAME.log
```

Samples are processed in increasing order of cleaned FASTQ file size.

Completed samples are skipped when their gene-family output already
exists.

------------------------------------------------------------------------

# 18. Merging HUMAnN results

Unlike MetaPhlAn, HUMAnN per-sample outputs are **not merged inside
`MG_pipeline.sh`**.

After the main pipeline has completed, run:

``` bash
bash merge_results.sh PROJECT_NAME OUTPUT_DIRECTORY
```

Example:

``` bash
bash merge_results.sh TEST_pipeline /home/biox/MG_results/TEST_pipeline
```

The script collects the HUMAnN outputs from:

``` text
~/TEST_pipeline/results/04_humann3/per_sample/
```

and creates multicample functional matrices in:

``` text
/home/biox/MG_results/TEST_pipeline/
```

This output directory is intentionally separate from the project
directory.

------------------------------------------------------------------------

# 19. Merged HUMAnN outputs

After merging, the output directory contains:

``` text
genefamilies.tsv
genefamilies_cpm.tsv
genefamilies_cpm_stratified.tsv
genefamilies_cpm_unstratified.tsv

pathabundance.tsv
pathabundance_cpm.tsv
pathabundance_cpm_stratified.tsv
pathabundance_cpm_unstratified.tsv

pathcoverage.tsv
```

## Gene families

``` text
genefamilies.tsv
```

Raw merged HUMAnN gene-family table.

``` text
genefamilies_cpm.tsv
```

CPM-normalized merged table.

``` text
genefamilies_cpm_stratified.tsv
```

Taxonomically stratified gene-family table.

``` text
genefamilies_cpm_unstratified.tsv
```

Unstratified gene-family table.

## Pathways

``` text
pathabundance.tsv
```

Merged pathway abundance table.

``` text
pathabundance_cpm.tsv
```

CPM-normalized pathway abundance.

``` text
pathabundance_cpm_stratified.tsv
```

Taxonomically stratified pathway abundance.

``` text
pathabundance_cpm_unstratified.tsv
```

Unstratified pathway abundance.

## Pathway coverage

``` text
pathcoverage.tsv
```

Merged pathway coverage table.

Coverage is kept on its original 0--1 scale and is not converted to CPM.

------------------------------------------------------------------------

# 20. CPM normalization

`merge_results.sh` uses HUMAnN's:

``` text
humann_renorm_table
```

with:

``` text
--units cpm
--update-snames
```

for:

-   gene-family abundance
-   pathway abundance

The resulting sample columns are explicitly labelled as CPM.

For a correctly normalized CPM table, the total abundance per sample is
approximately:

``` text
1,000,000
```

small deviations can occur because of numerical rounding.

The validated test produced approximately:

``` text
Gene families:
sample 1 ≈ 1,000,000 CPM
sample 2 ≈ 1,000,000 CPM

Pathway abundance:
sample 1 ≈ 1,000,000 CPM
sample 2 ≈ 1,000,000 CPM
```

Pathway coverage is different and remains between 0 and 1.

------------------------------------------------------------------------

# 21. Stratified vs unstratified tables

HUMAnN can report a functional feature:

1.  without taxonomic attribution
2.  stratified by the organism contributing to that function

For example, a gene-family table may contain:

``` text
UniRef90_E4W3A3
```

and:

``` text
UniRef90_E4W3A3|g__Bacteroides.s__Bacteroides_fragilis
```

The first represents the unstratified functional feature.

The second represents the same function attributed to a specific taxon.

Use:

``` text
*_cpm_unstratified.tsv
```

when the main question concerns overall functional abundance.

Use:

``` text
*_cpm_stratified.tsv
```

when the taxonomic contribution to a function is of interest.

------------------------------------------------------------------------

# 22. Example: complete analysis from scratch

Assume the project is called:

``` text
epilepsy_project
```

and the FASTQ files are:

``` text
~/epilepsy_project/raw_fastq/
├── sample01.1.fastq.gz
├── sample01.2.fastq.gz
├── sample02.1.fastq.gz
└── sample02.2.fastq.gz
```

## Run the main pipeline

``` bash
cd /home/biox/MG-Processing

screen -S epilepsy_metagenomics

bash MG_pipeline.sh epilepsy_project
```

Detach:

``` text
Ctrl+A
D
```

Reconnect later:

``` bash
screen -r epilepsy_metagenomics
```

## Check the main outputs

``` bash
ls -lh ~/epilepsy_project/results/03_metaphlan/
```

and:

``` bash
ls -lh ~/epilepsy_project/results/04_humann3/per_sample/
```

## Merge HUMAnN results

After all samples have completed:

``` bash
bash merge_results.sh \
    epilepsy_project \
    /home/biox/MG_results/epilepsy_project
```

Final functional matrices:

``` text
/home/biox/MG_results/epilepsy_project/
├── genefamilies.tsv
├── genefamilies_cpm.tsv
├── genefamilies_cpm_stratified.tsv
├── genefamilies_cpm_unstratified.tsv
├── pathabundance.tsv
├── pathabundance_cpm.tsv
├── pathabundance_cpm_stratified.tsv
├── pathabundance_cpm_unstratified.tsv
└── pathcoverage.tsv
```

------------------------------------------------------------------------

# 23. Recommended pre-run checks

Before starting a large project, check:

## FASTQ files

``` bash
ls -lh ~/PROJECT_NAME/raw_fastq/
```

Verify that every sample has both:

``` text
sample.1.fastq.gz
sample.2.fastq.gz
```

## FASTQ integrity

For compressed FASTQ files:

``` bash
gzip -t ~/PROJECT_NAME/raw_fastq/*.fastq.gz
```

For large datasets this can take some time.

## Script syntax

``` bash
bash -n MG_pipeline.sh
bash -n merge_results.sh
```

## Environment versions

``` bash
/home/biox/mambaforge/envs/MG-Shotgun/bin/metaphlan --version
/home/biox/mambaforge/envs/HUMAnN-func/bin/humann --version
/home/biox/mambaforge/envs/HUMAnN-func/bin/metaphlan --version
/home/biox/mambaforge/envs/HUMAnN-func/bin/diamond version
/home/biox/mambaforge/envs/MG-Shotgun/bin/bowtie2 --version
```

Expected critical versions:

``` text
MG-Shotgun MetaPhlAn   4.2.5
HUMAnN                 3.9
HUMAnN-func MetaPhlAn  4.1.1
```

------------------------------------------------------------------------

# 24. Monitoring HUMAnN

For long analyses, use:

``` bash
bash monitor_humann.sh
```

The monitoring script can be used to inspect:

-   running HUMAnN processes
-   sample progress
-   logs
-   completed samples

The main HUMAnN logs are stored in:

``` text
PROJECT_NAME/results/04_humann3/logs/
```

------------------------------------------------------------------------

# 25. Restarting a failed HUMAnN sample

If a sample fails, use:

``` bash
bash restart_humann.sh SAMPLE_NAME
```

The restart workflow is intended to avoid recomputing samples that have
already completed successfully.

Before restarting, inspect the corresponding log:

``` text
PROJECT_NAME/results/04_humann3/logs/SAMPLE_NAME.log
```

------------------------------------------------------------------------

# 26. Troubleshooting

## 26.1 `Bowtie2 not found`

Check:

``` bash
which bowtie2
```

For the HUMAnN environment:

``` bash
/home/biox/mambaforge/envs/HUMAnN-func/bin/bowtie2 --version
```

For the taxonomic environment:

``` bash
/home/biox/mambaforge/envs/MG-Shotgun/bin/bowtie2 --version
```

The main pipeline does not rely on the shell `PATH` alone: it calls the
executables using their explicit environment paths.

------------------------------------------------------------------------

## 26.2 MetaPhlAn 4.2 / HUMAnN compatibility error

Do not replace the HUMAnN-func MetaPhlAn version with the standalone
MetaPhlAn 4.2.x version.

Check:

``` bash
/home/biox/mambaforge/envs/HUMAnN-func/bin/metaphlan --version
```

The validated HUMAnN environment uses:

``` text
MetaPhlAn 4.1.1
```

The standalone taxonomy environment uses:

``` text
MetaPhlAn 4.2.5
```

------------------------------------------------------------------------

## 26.3 ChocoPhlAn version error

If HUMAnN reports:

``` text
The directory provided for ChocoPhlAn contains files that are not of the expected version
```

check the configured path:

``` bash
/home/biox/mambaforge/envs/HUMAnN-func/bin/humann_config --print
```

and verify that the nucleotide database points to the directory
containing the actual:

``` text
*.v201901_v31.ffn.gz
```

files.

------------------------------------------------------------------------

## 26.4 UniRef version error

If HUMAnN reports:

``` text
The directory provided for the translated database contains files
that are not of the expected version
```

check:

``` bash
/home/biox/mambaforge/envs/HUMAnN-func/bin/humann_config --print
```

The validated UniRef database contains:

``` text
uniref90_201901b_full.dmnd
```

and the configured protein database path must point to the directory
containing that file.

------------------------------------------------------------------------

## 26.5 HUMAnN utility mapping path

Check:

``` bash
/home/biox/mambaforge/envs/HUMAnN-func/bin/humann_config --print
```

The utility mapping directory must point to the directory containing the
HUMAnN mapping files.

------------------------------------------------------------------------

## 26.6 `DIAMOND` errors or bus errors

Check:

``` bash
/home/biox/mambaforge/envs/HUMAnN-func/bin/diamond version
```

Potential causes include:

-   insufficient memory
-   database/storage problems
-   incorrect environment
-   incompatible software/database versions

Keep large reference databases on a native Linux filesystem when
possible.

------------------------------------------------------------------------

# 27. What the pipeline produces

At the end of the main pipeline, the project contains:

## Quality control

``` text
PROJECT_NAME/results/01_qc/
```

## Host-removed reads

``` text
PROJECT_NAME/results/02_host_removed/
```

## Taxonomy

``` text
PROJECT_NAME/results/03_metaphlan/
├── SAMPLE_profile.tsv
├── SAMPLE_bt2.bz2
└── merged_abundance_table.tsv
```

## HUMAnN functional profiling

``` text
PROJECT_NAME/results/04_humann3/
├── per_sample/
│   ├── SAMPLE1/
│   │   ├── SAMPLE1_genefamilies.tsv
│   │   ├── SAMPLE1_pathabundance.tsv
│   │   └── SAMPLE1_pathcoverage.tsv
│   └── SAMPLE2/
│       └── ...
└── logs/
```

After running `merge_results.sh`, the final multicample functional
matrices are stored in the user-specified output directory, for example:

``` text
/home/biox/MG_results/PROJECT_NAME/
```

------------------------------------------------------------------------

# 28. Validated two-sample test

The pipeline was validated using two paired-end samples:

``` text
mgshot_S16781Nr1
mgshot_S16781Nr2
```

The test successfully generated:

-   FastQC reports
-   host-removed paired FASTQ files
-   two MetaPhlAn profiles
-   a merged MetaPhlAn abundance table
-   two HUMAnN gene-family tables
-   two HUMAnN pathway-abundance tables
-   two HUMAnN pathway-coverage tables
-   merged gene-family matrices
-   merged pathway-abundance matrices
-   merged pathway-coverage matrix
-   CPM-normalized gene-family tables
-   CPM-normalized pathway-abundance tables
-   stratified and unstratified CPM tables

The merged CPM tables were checked and showed approximately 1,000,000
CPM per sample.

The pathway coverage matrix was checked and all values were within the
expected 0--1 range.

Therefore, the workflow has been tested end-to-end before processing the
full dataset.

------------------------------------------------------------------------

# 29. Important reproducibility note

The pipeline intentionally keeps:

``` text
software environments
+
reference databases
```

separate from:

``` text
project inputs
+
project outputs
```

This means that multiple projects can use the same installed software
and databases without reinstalling them.

For reproducibility, keep a record of:

-   pipeline repository commit/version
-   `config/config.sh`
-   software versions
-   database versions
-   project name
-   sample list
-   analysis date

Do not update the MetaPhlAn/HUMAnN environments in the middle of a
project unless the entire workflow is deliberately revalidated.

------------------------------------------------------------------------

# 30. Quick reference

## Main pipeline

``` bash
cd /home/biox/MG-Processing
bash MG_pipeline.sh PROJECT_NAME
```

## Merge HUMAnN results

``` bash
bash merge_results.sh PROJECT_NAME OUTPUT_DIRECTORY
```

Example:

``` bash
bash merge_results.sh \
    TEST_pipeline \
    /home/biox/MG_results/TEST_pipeline
```

## Monitor

``` bash
bash monitor_humann.sh
```

## Restart a sample

``` bash
bash restart_humann.sh SAMPLE_NAME
```

## Check script syntax

``` bash
bash -n MG_pipeline.sh
bash -n merge_results.sh
```

## Check active screen sessions

``` bash
screen -ls
```

## Reconnect to a screen

``` bash
screen -r SESSION_NAME
```

or, if already attached elsewhere:

``` bash
screen -d -r SESSION_NAME
```

------------------------------------------------------------------------

# 31. Summary of the validated workflow

``` text
Raw paired-end FASTQ
        |
        v
      FastQC
        |
        v
  Host removal
  GRCh38 / Bowtie2
        |
        +----------------------+
        |                      |
        v                      v
 MetaPhlAn 4.2.5          HUMAnN 3.9
        |                      |
        |                MetaPhlAn 4.1.1
        |                      |
        v                      v
 Taxonomic profiles       Functional profiles
        |                      |
        v                +-----+-----+
Merged taxonomy          |     |     |
                         v     v     v
                      Gene  Pathway Coverage
                     families abundance
                         \     |     /
                          \    |    /
                           v   v   v
                       merge_results.sh
                              |
                              v
                     Multisample matrices
                              |
                    +---------+---------+
                    |                   |
                    v                   v
                  CPM              Coverage 0–1
              normalized
```

The resulting taxonomic and functional matrices are ready for downstream
microbiome analyses.