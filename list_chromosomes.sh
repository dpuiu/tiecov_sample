#!/bin/bash -e

# Script that lists all chromosomes present in all input bedGraph files.

# Read lines (filenames) from standard input, one by one
while read -r line; do
  # For each file:
  #   - list all reference sequences (chromosomes) in the tabix-indexed file
  #   - append the filename to the end of each output line
  tabix -l "$line" \
    | sed "s|$|\t$line|"
done
