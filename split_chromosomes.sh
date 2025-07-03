#!/bin/bash -e

# Script that splits bedGraph files by chromosome

if [[ $in != *.gz ]]; then
  echo "gz file extension expected"
  exit 1
fi

tmp="tmp"
#prefix=`basename $1 .sample.bedGraph.gz`
prefix="${1%%.*}"
tmp="$tmp.$prefix"

test -s $1
for chr in $(tabix -l $1); do
    echo "tabix $1 $chr | bgzip > $tmp.$chr.gz; tabix -p bed $tmp.$chr.gz"
done
