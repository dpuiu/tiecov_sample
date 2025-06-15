#!/bin/bash -e

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 file1 [file2 ...] chromosome"
  exit 1
fi

# Get the last argument as chromosome
chromosome="${!#}"

# All arguments except the last are files
files=("${@:1:$#-1}")

for file in "${files[@]}"; do
  test -s $file
  tabix "$file" "$chromosome"
done

