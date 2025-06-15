#!/usr/bin/env pypy

"""
Script to merge consecutive genomic intervals with matching properties.

Input format (tab-separated, 4 fields per line):
    chrom  start  end  value

Output:
    Merged lines where chrom, value, and adjacent intervals match.
"""

import sys
import signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)


def main():
    prev = []

    for lineno, line in enumerate(sys.stdin, 1):
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
    main()

