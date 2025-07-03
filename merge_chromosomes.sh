#!/bin/bash -e

# Script that merges chromosomes bedGraph files

if [[ $1 != *.gz ]]; then
  echo "gz file extension expected"
  exit 1
fi

tmp="tmp"
#prefix=`basename $1 .sample.bedGraph.gz`
prefix="${1%%.*}"
tmp="$tmp.$prefix"

echo "ls $tmp.*.gz | sort -f | xargs cat > $1; tabix -p bed $1"
