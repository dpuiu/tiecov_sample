# tiecov_sample.sh

---

## Purpose

Compute **sample coverage** from multiple input **bam**, **cram**, or **bedGraph** files.

**Repository:** [tiecov_sample](https://github.com/dpuiu/tiecov_sample/)  
Related project: [tiebrush](https://github.com/alevar/tiebrush)

---

## Overview

`tiecov_sample` is a lightweight toolkit designed to compute per-sample coverage from multiple cram/bam/bedGraph files. 
It outputs compressed and indexed bedGraph files suitable for further analysis or visualization.

---

## Example Usage

```bash
# Compute per-sample coverage for Tissue_1 ...
tiecov_sample.sh            -o Tissue_1.sample.bedGraph.gz Tissue_1/*.cram

# Use a common reference for Tissue_2
tiecov_sample.sh -r ref.ids -o Tissue_2.sample.bedgGaph.gz Tissue_2/*.cram  # if all samples used the same referemce

# Merge sample coverage across multiple tissues
tiecov_sample.sh -r ref.ids -o Tissues.sample.bedGraph.gz -p 16 Tissue_*.sample.bedGraph.gz
```

### Input Files

ref.ids  
A list of reference regions (e.g., from samtools faidx).  
Use this file if all input CRAMs were aligned to the same reference.  
Each line can be:  
  A chromosome (chr1)  
  A chromosome region (chr1:100000-200000)  

Sample/Tissue files
  *.bam       - Input bam files
  *.cram      - Input cram files  
  *.gz        - Input bedGraph files

### Output Files

Tissues file
  *.gz        - Compressed bedGraph files with total sample coverage  

---

## Requirements

The following tools must be installed and available in your system $PATH:  
* [samtools](https://github.com/samtools)  
* [tabix](https://github.com/samtools/tabix)   
* [parallel](https://gnu.org)  
* [bgzip](https://github.com/samtools/htslib)  
* [readlink](https://www.gnu.org/software/coreutils/)  
* [pypy3](https://pypy.org)  (optional; defaults to python3)
 
To install most of these on a Debian-based system:

```bash
sudo apt update
sudo apt install samtools tabix parallel coreutils pypy3 python3
```
