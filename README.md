# tiecov_sample.sh

---

## Purpose

Compute **sample coverage** from multiple input **BAM**, **CRAM**, or **bedGraph** files.

**Repository:** [tiecov_sample](https://github.com/dpuiu/tiecov_sample/)  
Related project: [tiebrush](https://github.com/alevar/tiebrush)

---

## Overview

`tiecov_sample` is a lightweight toolkit designed to compute per-sample coverage from multiple CRAM/BAM/bedGraph files. 
It outputs compressed and indexed bedGraph files suitable for further analysis or visualization.

---

## Example Usage

```bash
# Compute per-sample coverage for Tissue_1 
tiecov_sample.sh            -o Tissue_1.sample.bedGraph.gz Tissue_1/*.cram

# Use a common reference for Tissue_2 (if all samples used the same reference)
tiecov_sample.sh -r ref.ids -o Tissue_2.sample.bedgGaph.gz Tissue_2/*.cram 

# Merge sample coverage across multiple tissues
tiecov_sample.sh -r ref.ids -o Tissues.sample.bedGraph.gz -p 16 Tissue_*.sample.bedGraph.gz
```

### Input Files

Sample/Tissue files:  
    *.bam       - BAM  alignemnt files  
    *.cram      - CRAM alignemnt files  
    *.gz        - bedGraph coverage files  

ref.ids  
    A file containing a list of reference regions (e.g., from samtools faidx).    
    Use this file if all input files were aligned to the same reference.    
    Each line can be:  
       A chromosome (chr1)  
       A chromosome region (chr1:100000-200000)  

### Output Files

Tissues file:  
    *.gz        - Compressed bedGraph file with total sample coverage  

Example
    $ zcat Tissues.sample.bedGraph.gz
    chr1	9999	10003	1	# chr1:9999-10003 region covered by a single sample(multiple reads?)
    chr1	10003	10004	3	# chr1:9993-10004 region covered by 3 samples
    chr1	10004	10010	5	# ...
    chr1	10010	10011	7
    chr1	10011	10013	8


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

## Links

* [Sequence Alignment/Map Format Specification](https://samtools.github.io/hts-specs/SAMv1.pdf)
* [CRAM format specification](https://samtools.github.io/hts-specs/CRAMv3.pdf)
* [bedGraph format](https://genome.ucsc.edu/goldenpath/help/bedgraph.html)
