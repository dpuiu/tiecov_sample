#!/bin/bash -e

# Script that lists all chromosomes present in all input files.

# Get the absolute path to the directory containing this script.
# This allows the script to call other scripts in the same directory reliably,
# regardless of where the script is run from.
script_path=$(dirname $(readlink -f $0))
PYTHON=$(command -v pypy3 || command -v python3)

# Read lines (filenames) from standard input, one by one
while read -r line; do
  # For each file:
  #   - extract the SAM header using samtools view -H
  #   - pass it to extract_chromosomes.py in the same directory
  #   - append the original filename to each output line
  samtools view -H "$line" \
    | $PYTHON $script_path/extract_chromosomes.py \
    | sed "s|$|\t$line|"
done
