#!/usr/bin/env pypy3

"""
Aggregate BEDGRAPH intervals.

This script reads intervals from a BEDGRAPH-like format from stdin,
and outputs merged intervals with aggregated coverage.

It supports input lines with 3, 4, or 6 fields:
- 3 fields: chrom, start, end (assumes +1 coverage)
- 4 fields: chrom, start, end, value
- 6 fields: chrom, start, end, name, value, strand

Optionally, a genome length file can be provided via `-g` to define end boundaries.

Usage examples:
    cat input.bedgraph |  sys.argv[1]
    sys.argv[1] -g genome.len < input.bedgraph

"""

import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description="Aggregate BEDGRAPH intervals.")
    parser.add_argument('-g', metavar='GENOME', help='Genome length file (tab-delimited: chrom<TAB>length)', required=False)
    args = parser.parse_args()

    # Store changes in coverage per chrom and position
    coverage_map = {}

    for line in sys.stdin:
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

    # Incorporate genome length file to ensure coverage ends at chromosome boundaries
    if args.g:
        try:
            with open(args.g, 'r') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    parts = line.split('\t')
                    if len(parts) < 2:
                        raise ValueError(f"ERROR: Malformed genome line: {line}")
                    chrom, length_str = parts[0], parts[1]
                    length = int(length_str)
                    coverage_map.setdefault(chrom, {})
                    cov = coverage_map[chrom]
                    cov.setdefault(0, 0)
                    cov.setdefault(length, 0)
        except IOError as e:
            print(f"ERROR: Could not open genome file: {e}", file=sys.stderr)
            sys.exit(1)

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
    main()
