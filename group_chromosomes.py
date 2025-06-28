#!/usr/bin/env pypy3

"""
Script that groups input lines by chromosome.

This script reads lines from standard input, expecting each line to contain
at least two whitespace-separated fields. The first field is treated as the
chromosome name (key), and the second field as a sample associated with that chromosome.

The script collects all samples associated with each chromosome and outputs
each chromosome followed by a tab and a space-separated list of its associated samples.

Input format (tab- or space-separated, at least two fields per line):

    chrom  sample

Example input:

    chr1  sampleA
    chr2  sampleB
    chr1  sampleC
    chr3  sampleD

Example output:

    chr1  sampleA sampleC
    chr2  sampleB
    chr3  sampleD

Usage:

    cat input.txt | group_chromosomes.py
"""

import sys
import signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

from collections import defaultdict

def group_chromosomes(file):
    groups = defaultdict(list)
    for line in file:
        parts = line.strip().split('\t')
        if len(parts) < 2:
            continue
        key, val = parts[0], parts[1]
        groups[key].append(val)
    for i, key in enumerate(sorted(groups), start=1):
        print(f"{i}\t{key}\t{' '.join(groups[key])}")

if __name__ == "__main__":
    group_chromosomes(sys.stdin)

