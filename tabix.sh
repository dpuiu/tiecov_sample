#!/bin/bash -e

# Script that queries multiple tabix-indexed files for a specific chromosome region.

# Exit if fewer than 2 arguments are given.
# The minimum required is:
#   - at least one file
#   - a chromosome name
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 file1 [file2 ...] chromosome"
  exit 1
fi

# Get the last argument as the chromosome name.
# "${!#}" expands to the value of the last positional argument.
chromosome="${!#}"

# Collect all arguments except the last one into an array called 'files'.
# "${@:1:$#-1}" expands from argument 1 up to argument $#-1
files=("${@:1:$#-1}")

# Loop over all input files
for file in "${files[@]}"; do
  # Check that the file is non-empty
  test -s "$file"

  # Query the tabix-indexed file for the specified chromosome
  tabix "$file" "$chromosome"
done
