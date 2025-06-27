#!/usr/bin/env pypy3

"""
Script that merges consecutive genomic intervals that have identical coverage values.

Input format:
    A tab-separated file with four columns per line:
        chrom    start    end    coverage
    where:
        - chrom: chromosome name (string)
        - start: interval start position (integer, zero-based, inclusive)
        - end: interval end position (integer, zero-based, exclusive)
        - coverage: coverage value (integer or float)

Output format:
    Same as input: tab-separated with columns
        chrom    start    end    coverage

Merging criteria:
    - Intervals are on the same chromosome
    - Coverage values are equal
    - Intervals are directly adjacent (the end coordinate of one equals the start coordinate of the next)

Usage:
    cat intervals.bedGraph | merge_intervals.py > merged_intervals.bedGraph

Example:
    Input file (intervals.bedGraph):
        chr1    10    20    5
        chr1    20    30    5
        chr1    30    40    3
        chr2    5     15    2
        chr2    15    25    2

    Command:
        cat intervals.bedGraph | python merge_intervals.py

    Output:
        chr1    10    30    5
        chr1    30    40    3
        chr2    5     25    2
"""

##########################

import sys
import signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

def merge_coverage(file):
    prev = []

    for lineno, line in enumerate(file, 1):
        fields = line.strip().split()
        if len(fields) != 4:
            sys.stderr.write(f"Error on line {lineno}: expected 4 fields, got {len(fields)} → {line}")
            sys.exit(1)

        if not prev:
            prev = fields
        elif prev[0] != fields[0] or prev[2] != fields[1] or prev[3] != fields[3]:
            print('\t'.join(prev))
            prev = fields
        else:
            prev[2] = fields[2]  # Extend end position

    if prev:
        print('\t'.join(prev))

if __name__ == "__main__":
    merge_coverage(sys.stdin)

