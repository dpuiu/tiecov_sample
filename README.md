# tiecov_sample.sh

Script to compute **sample coverage** from multiple input **BAM/CRAM/BEDGRAPH** files.

**Repository:** [tiecov_sample](https://github.com/dpuiu/tiecov_sample/)  
Related project: [tiebrush](https://github.com/alevar/tiebrush)

---

## Overview

`tiecov_sample` is a lightweight toolkit designed to compute per-sample coverage from multiple CRAM or BAM files. It outputs compressed and indexed BedGraph files suitable for further analysis or visualization.

---

## Example Usage

```bash
# Compute per-sample coverage for Tissue_1,2 ...
tiecov_sample.sh -ri ref.fa.fai -s Tissue_1.sample.bedgraph.gz -p 16 Tissue_1/*.cram
tiecov_sample.sh -ri ref.fa.fai -s Tissue_2.sample.bedgraph.gz -p 16 Tissue_2/*.cram
...

# Merge sample coverages across tissues
tiecov_sample.sh -ri ref.fa.fai -s Tissues.sample.bedgraph.gz -p 16 Tissue_*.sample.bedgraph.gz

```

### Input Files

ref.fa                 – Reference genome in FASTA format  
ref.fa.fai             – Index of the reference FASTA (generated using samtools faidx)  
Tissue_\*/\*.cram      – Input CRAM files
Tissue_\*/\*.cram.crai – CRAM index files

### Output Files

Tissues.sample.bedgraph.gz     – Compressed BedGraph files with total sample coverage  
Tissues.sample.bedgraph.gz.tbi – Tabix index files for fast querying  

---

## Requirements

The following tools must be installed and available in your system $PATH:  
[samtools](https://github.com/samtools)
[tabix](https://github.com/samtools/tabix)  
[parallel](https://gnu.org)
[bgzip](https://github.com/samtools/htslib)
[readlink](https://www.gnu.org/software/coreutils/)
[pypy3](https://pypy.org)

To install most of these on a Debian-based system:

```bash
sudo apt update
sudo apt install samtools tabix parallel coreutils pypy3
```
