#!/bin/bash -e

# Initialize default values
opt_dry_run=false
tmp="tmp"
cram_files=()
bedgraph_files=()
P=12

# Help message
print_help() {
    echo "Script which computes the sample covearge from multiple BAM/CRAM indexed files"
    echo
    echo "Usage: $0 [options] <input_files>"
    echo
    echo "Options:"
    echo "  -h, --help         Display this help and exit"
    echo "  -rf <file>         Reference FASTA file"
    echo "  -ri <index>        Reference FASTA index (chr names or regions in 1st column)"
    echo "  -p <threads>       Number of parallel threads"
    echo "  -s <sample>        Output sample file name"
    echo
    echo "input_files: sorted & indexed BAM/CRAM files"
    echo
    echo "  $0 -rf ref.fa [-ri ref.fa.fai] [ -p 12 ] -s output.bedgraph.gz input1.bam [input2.bam ...]"
    echo
    echo "Example:"
    echo
    echo "  $0 -rf ref.fa -s Tissue.sample.bedgraph.gz Tissue/*.cram"
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: $1 not found." >&2
    exit 1
  }
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
	-rf)
	    ref_file="$2"
            shift 2
            ;;
       -ri)
            ref_index="$2"
            shift 2
            ;;
        -p)
            P="$2"
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
           case "$1" in
              *.cram)         cram_files+=("$1") ;;
              *.bam)          cram_files+=("$1") ;;
              *.bedgraph.gz)  bedgraph_files+=("$1") ;;
              *)              echo "Unknown extension" ; exit 1 ;;
            esac

            if ! [[ -s "$1" &&  -r "$1" ]] ; then
              echo "Error: input file $1 does not exist or is unreadable"
              exit 1
            fi

            shift
            ;;
    esac
done

#########################################################
# test ref_file or ref_index are defined

if [ -n "$ref_index" ] ; then
  :  # Do nothing; ref_index already set
elif [ -n "$ref_file" ] ; then
  ref_index="$ref_file.fai"
else
  echo "Error: option -rf or -ri must be defined; use -h for details"
  exit 1
fi

#########################################################
# test ref_index exists and is readable
if  ! [[ -s "$ref_index" &&  -r "$ref_index" ]] ; then
  echo "Error:  can not read $ref_index file"
  exit 1
fi

#########################################################
# test out_sample is defined

if ! [ -n "$out_sample" ] ; then
  echo "Error: option -s must be defined; use -h for details"
  exit 1
fi

sample_prefix="${out_sample%%.*}"
#########################################################
# check at least one BAM/CRAM file is provided

if [[ ${#cram_files[@]} -eq 0 && ${#bedgraph_files[@]} -eq 0 ]] ; then
  echo "Error: No BAM/CRAM/BEDGRAPH files provided."
  exit 1
elif [[ ${#cram_files[@]} -gt 0 && ${#bedgraph_files[@]} -gt 0 ]] ; then
  echo "Error: Either BAM/CRAM or BEDGRAPH must be files provided."
fi

#########################################################
# check commands installed

for cmd in pypy parallel bgzip tabix samtools readlink; do
  check_cmd "$cmd"
done

#########################################################
# set path

script_path=$(dirname $(readlink -f $0))
script_prefix="${0%.*}"

#########################################################
# compute covearge (per chr)

rm -f $script_prefix.$sample_prefix.sh

if [[ -s $out_sample && -s $out_sample.tbi ]] ; then
  echo "File $out_sample already exists"
  exit 0
fi

#########################################################
# per chromosome

sort -k2,2nr $ref_index | cut -f1 | while read -r chr; do
  if ! [[ -s $tmp.$sample_prefix.$chr.bedgraph.gz && -s $tmp.$sample_prefix.$chr.bedgraph.gz.tbi ]] ; then
      if [ ${#cram_files[@]} -gt 0 ] ; then
        echo -n "samtools depth ${cram_files[*]} -r $chr         | $script_path/count_coverage.py  | $script_path/merge_coverage.py " >> $script_prefix.$sample_prefix.sh
      else
        echo -n "$script_path/tabix.sh ${bedgraph_files[*]} $chr | $script_path/sum_coverage.py " >> $script_prefix.$sample_prefix.sh
      fi
      echo "| bgzip > $tmp.$sample_prefix.$chr.bedgraph.gz; tabix -p bed $tmp.$sample_prefix.$chr.bedgraph.gz" >> $script_prefix.$sample_prefix.sh
  fi
done
#########################################################
# run in parallel; aggregate at the end

if ! [ "$opt_dry_run" = "true" ]; then
  cat $script_prefix.$sample_prefix.sh | parallel -j $P
  ls $tmp.$sample_prefix.*.bedgraph.gz | sort -f | xargs cat > $out_sample   ; tabix -p bed $out_sample
  tabix -l $out_sample
  rm $tmp.$sample_prefix.*.bedgraph.gz $tmp.$sample_prefix.*.bedgraph.gz.tbi
else
  cat $script_prefix.$sample_prefix.sh
  echo "ls $tmp.$sample_prefix.*.bedgraph.gz | sort -f | xargs cat > $out_sample   ; tabix -p bed $out_sample"
fi
