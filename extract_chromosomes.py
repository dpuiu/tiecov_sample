#!/usr/bin/env pypy3

"""
Script that extracts chromosome names from a SAM header.

This script reads SAM-format data from standard input and parses all @SQ lines
to extract chromosome names (i.e. reference sequence names). It stops reading
once the SAM header ends—that is, when the first alignment record is encountered.

Example input (SAM header lines):

    @HD     VN:1.6  SO:coordinate
    @SQ     SN:chr1 LN:248956422
    @SQ     SN:chr2 LN:242193529
    @SQ     SN:chrM LN:16569
    @PG     ID:samtools PN:samtools VN:1.10

Example output:

    chr1
    chr2
    chrM

Output:
    A list of chromosome names, one per line.

Usage example:
    samtools view -H sample.bam | python extract_chromosomes.py
"""

import sys
import signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

def extract_chromosomes(file):
    chromosomes = []
    for line in file:
        if line.startswith("@SQ"):
            fields = line.strip().split("\t")
            for field in fields:
                if field.startswith("SN:"):
                    chrom = field[3:]  # strip "SN:"
                    chromosomes.append(chrom)
        elif not line.startswith("@"):
            # Header ended
            break
    return chromosomes

if __name__ == "__main__":
    chroms = extract_chromosomes(sys.stdin)
    for chrom in chroms:
        print(f"{chrom}")
