#!/usr/bin/env pypy3

"""
Script that takes as input a file generated by `samtools depth` and aggregates coverage across samples.

Example input (from samtools depth):

    samtools depth sample1.cram sample2.cram sample3.cram -r chrM | head -n 3

    #chr    pos    s1    s2    s3
    chrM     1      0    88    65
    chrM     2     55    77     8
    chrM     3     58    64     0

Example output (after aggregation by this script):

    #chr    start    end    num_samples_with_coverage
    chrM       0       1    2
    chrM       1       2    3
    chrM       2       3    2

Output format:

    chrom    start    end    num_samples_with_coverage

Usage example:

    samtools depth *.cram        | count_coverage.py
    samtools depth *.cram -r ref | count_coverage.py

Notes:

- This script counts how many samples have nonzero coverage at each genomic position.
- Consecutive positions with the same number of samples covered are merged into a single interval.
- The output uses zero-based, half-open coordinates: [start, end).
"""

import sys
import signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

def count_coverage(file):
    for lineno, line in enumerate(file, 1):
        fields = line.strip().split('\t')
        if len(fields) < 2:
            sys.stderr.write(f"Error on line {lineno}: fewer than 2 fields\n")
            sys.exit(1)

        try:
            nonzero_count = sum(1 for x in fields[2:] if int(x) != 0)
        except ValueError as e:
            sys.stderr.write(f"Error on line {lineno}: non-integer value in fields[2:]\n")
            sys.exit(1)

        if nonzero_count > 0:
            chrom = fields[0]
            start = int(fields[1]) - 1
            end = fields[1]
            print(f"{chrom}\t{start}\t{end}\t{nonzero_count}")

if __name__ == "__main__":
    count_coverage(sys.stdin)
