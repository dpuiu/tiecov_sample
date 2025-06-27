#!/usr/bin/env pypy3

"""
Script that aggregates intervals from a bedGraph input format.

This script reads intervals from standard input in a BEDGRAPH-like format
and outputs merged intervals with aggregated coverage values.

Supported input formats:
- 3 fields: chrom, start, end
    * Assumes a coverage value of 1 for each interval.
- 4 fields: chrom, start, end, value
    * Uses the provided coverage value.
- 6 fields: chrom, start, end, name, value, strand
    * Uses the provided coverage value and ignores other fields for aggregation.

Optionally, a genome length file can be specified with the `-g` flag.
This file should define chromosome lengths to properly handle interval boundaries.

Usage examples:
    cat input.bedGraph | sum_coverage.py
"""

import sys
import argparse

def sum_coverage(file):
    # Store changes in coverage per chrom and position
    coverage_map = {}

    for line in file:
        line = line.strip()
        if not line:
            continue

        fields = line.split('\t')
        num_fields = len(fields)

        if num_fields == 6:
            chrom, start, end, _, val, _ = fields
        elif num_fields == 4:
            chrom, start, end, val = fields
        elif num_fields == 3:
            chrom, start, end = fields
            val = 1
        else:
            raise ValueError(f"ERROR: Unexpected number of columns ({num_fields}) in line:\n{line}")

        start, end, val = int(start), int(end), int(val)

        if chrom not in coverage_map:
            coverage_map[chrom] = {}
        cov = coverage_map[chrom]
        cov[start] = cov.get(start, 0) + val
        cov[end] = cov.get(end, 0) - val

    # Clean zero-deltas (optional but reduces noise)
    for chrom in list(coverage_map):
        chrom_map = coverage_map[chrom]
        for pos in list(chrom_map):
            if chrom_map[pos] == 0:
                del chrom_map[pos]

    # Emit aggregated coverage intervals
    for chrom in sorted(coverage_map):
        positions = sorted(coverage_map[chrom])
        running_sum = 0
        prev_pos = None
        for pos in positions:
            if prev_pos is not None and running_sum != 0:
                print(f"{chrom}\t{prev_pos}\t{pos}\t{running_sum}")
            running_sum += coverage_map[chrom][pos]
            prev_pos = pos

if __name__ == "__main__":
    sum_coverage(sys.stdin)
