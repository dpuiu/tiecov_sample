#!/bin/bash -e

# Script that computes per-sample coverage from BAM/CRAM or bedGraph files.
# It automatically extracts chromosome lists, processes coverage by chromosome,
# and merges results into a single bedGraph.gz file with a tabix index.

########################################
# Initialize default values

opt_dry_run=false                # Whether to only print commands, not run them
tmp="tmp"                        # Prefix for temporary files
cram_files=()                    # Array to store BAM/CRAM input files
bedGraph_files=()                # Array to store bedGraph input files
is_crams=false                   # Flag to indicate whether CRAM/BAM mode is active
P=12                             # Default number of parallel threads
PYTHON=$(command -v pypy3 || command -v python3) # If pypy3 is installed, use it; otherwise, default to python3

########################################
# Define help message

print_help() {
    echo "Script which computes the sample coverage from multiple BAM/CRAM or bedGraph indexed files"
    echo
    echo "Usage: $0 [options] <input_files>"
    echo
    echo "Options:"
    echo "  -h, --help         Display this help and exit"
    echo "  -r  <index>        Reference FASTA index (.fai) to define chromosomes or regions"
    echo "  -p <threads>       Number of parallel threads (default: 12)"
    echo "  -s <sample>        Output sample file name (required)"
    echo "  --dry-run          Just print commands instead of executing"
    echo
    echo "input_files: sorted & indexed BAM/CRAM or bedGraph.gz files"
    echo
    echo "Example:"
    echo "  $0                     -s output.bedGraph.gz input1.cram input2.cram ..."
    echo "  $0 -r ref.fa.fai -p 12 -s output.bedGraph.gz input1.bam  input2.bam  ..."
    echo
}

########################################
# Check if external command is available

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: $1 not found." >&2
    exit 1
  }
}

########################################
# Parse command-line arguments

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        -p)
            P="$2"
            shift 2
            ;;
        -r)
            ref_index="$2"
            shift 2
            ;;
        --dry-run)
            opt_dry_run=true
            shift
            ;;
        -s)
            out_sample="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            # Determine file type based on file extension
            case "$1" in
                *.cram)         cram_files+=("$1") ;;
                *.bam)          cram_files+=("$1") ;;
                *.bedGraph.gz)  bedGraph_files+=("$1") ;;
                *)              echo "Missing input files or unknown extension" ; exit 1 ;;
            esac

            # Check that the input file exists and is readable
            if [[ ! -r "$1" ]] ; then
              echo "Error: input file $1 does not exist or is unreadable"
              exit 1
            fi

            shift
            ;;
    esac
done

########################################
# Check if reference index exists if provided

if [[ -n "$ref_index" ]] && [[ ! -r "$ref_index" ]] ; then
  echo "Error: reference index $ref_index does not exist or is unreadable"
  exit 1
fi

########################################
# Check that -s (sample output filename) is specified

if [[ ! -n "$out_sample" ]] ; then
  echo "Error: option -s must be defined; use -h for details"
  exit 1
fi

# Derive prefix for temporary files based on output filename
sample_prefix="${out_sample%%.*}"

# Check if output already exists (both file and tabix index)
if [[ -s $out_sample ]] && [[ -s $out_sample.tbi ]] ; then
  echo "File $out_sample already exists"
  exit 0
fi

# Compose unique tmp file prefix
tmp="$tmp.$sample_prefix"

########################################
# Ensure at least one input file was provided

if [[ ${#cram_files[@]} -eq 0 ]] && [[ ${#bedGraph_files[@]} -eq 0 ]] ; then
  echo "Error: No BAM/CRAM or bedGraph files provided."
  exit 1
elif [[ ${#cram_files[@]} -gt 0 ]] && [[ ${#bedGraph_files[@]} -gt 0 ]] ; then
  echo "Error: Either BAM/CRAM OR bedGraph files must be provided, not both."
elif [[ ${#cram_files[@]} -gt 0 ]] ; then
  printf "%s\n" "${cram_files[@]}" > $tmp.files
  is_crams=true
else
  printf "%s\n" "${bedGraph_files[@]}" > $tmp.files
fi

########################################
# Check that required tools are installed

for cmd in python3 parallel bgzip tabix samtools readlink; do
  check_cmd "$cmd"
done

########################################
# Determine path of helper scripts (assumed in same folder as this script)

script_path=$(dirname $(readlink -f $0))

########################################
# Create chromosome-to-file mapping

echo "Gathering files and chromosome ... "
if [[ -n "$ref_index" ]] ; then
  # Use the reference index (.fai) to list all chromosomes,
  # then compute cartesian product with file list
  cut -f1 $ref_index | $script_path/cartesian_product.sh /dev/stdin $tmp.files > $tmp.chr_files

elif [[ $is_crams == "true" ]] ; then
  # Extract chromosomes directly from CRAM/BAM headers
  cat $tmp.files | $script_path/extract_chromosomes.sh > $tmp.chr_files
else
  # For bedGraph input, list chromosomes using tabix -l
  cat $tmp.files | $script_path/list_chromosomes.sh > $tmp.chr_files
fi

########################################
# Prepare coverage computation commands for each chromosome

cat $tmp.chr_files \
  | $PYTHON $script_path/group_chromosomes.py \
  | tee $tmp.chr_files_grouped \
  | while read -r chr files; do

    # Skip chromosome if already processed and indexed
    if [[ ! -s "$tmp.$chr.bedGraph.gz.tbi" ]] ; then
      if [[ $is_crams == "true" ]] ; then
        # Construct pipeline for BAM/CRAM files
        echo -n "samtools depth $files -r $chr | $PYTHON $script_path/count_coverage.py | $PYTHON $script_path/merge_coverage.py " >> $tmp.sh
      else
        # Construct pipeline for bedGraph files
        echo -n "$script_path/tabix.sh $files $chr | $PYTHON $script_path/sum_coverage.py " >> $tmp.sh
      fi
      # Compress output and index with tabix
      echo "| bgzip > $tmp.$chr.bedGraph.gz ; tabix -p bed $tmp.$chr.bedGraph.gz" >> $tmp.sh
    fi
done

########################################
# Run coverage computation in parallel, or show commands if dry-run

if [[ ! "$opt_dry_run" == "true" ]] ; then
  # Execute all commands in parallel
  echo "Running $0 in parallel ... "
  cat $tmp.sh | parallel -j $P 2>/dev/null

  # Concatenate all per-chromosome bedGraph files into final output
  ls $tmp.*.bedGraph.gz | sort -f | xargs cat > $out_sample
  tabix -p bed $out_sample

  # Clean up temporary files
  rm $tmp.*
  
  echo "Done"
else
  # Print commands for inspection, but do not execute
  cat $tmp.sh
  echo "ls $tmp.*.bedGraph.gz | sort -f | xargs cat > $out_sample ; tabix -p bed $out_sample"
fi
