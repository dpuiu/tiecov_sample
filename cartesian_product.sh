#!/bin/bash -e

# Script that performs a pairwise combination of lines from two files.
# For every line in file1, it pairs it with every line in file2,
# printing all combinations in a tab-separated format.

# Read filenames from the first and second script arguments
file1="$1"
file2="$2"

# Outer loop: read each line from file1
while read -r line1; do
  # Inner loop: read each line from file2
  while read -r line2; do
    # Print the pair: line from file1 and line from file2, separated by a tab
    echo -e "${line1}\t${line2}"
  done < "$file2"
done < "$file1"
