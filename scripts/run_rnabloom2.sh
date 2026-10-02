#!/usr/bin/env bash
# Assemble RNA-seq reads with RNA-Bloom2 already available on PATH.
set -euo pipefail

THREADS=4
OUTDIR=""
MODE=""
READ1=""
READ2=""
EXTRA=()

usage() {
  cat <<'EOF'
Usage:
  scripts/run_rnabloom2.sh --single READS.fa[.gz] --outdir OUTPUT [options] [-- RNA-Bloom options]
  scripts/run_rnabloom2.sh --left LEFT.fa[.gz] --right RIGHT.fa[.gz] --outdir OUTPUT [options] [-- RNA-Bloom options]
  scripts/run_rnabloom2.sh --long READS.fa[.gz] --outdir OUTPUT [options] [-- RNA-Bloom options]

Required:
  --single FILE       Single-end forward reads (FASTA/FASTQ, optionally gzip-compressed).
  --left FILE         Paired-end left reads; requires --right.
  --right FILE        Paired-end right reads; requires --left.
  --long FILE         Long reads (ONT or PacBio).
  --outdir DIR        Directory RNA-Bloom2 will write to.

Options:
  --threads N         CPU threads to use (default: 4).
  --force             Permit an existing, non-empty output directory.
  -h, --help          Show this help.

Everything after -- is passed unchanged to RNA-Bloom2. This is where you
can keep control of its exact launch settings, e.g. -- -revcomp-right -mem 32.

Examples:
  # Single-end short reads
  scripts/run_rnabloom2.sh --single reads.fa --outdir results/sample1 --threads 16

  # Paired-end reads, with your RNA-Bloom2 settings appended
  scripts/run_rnabloom2.sh --left sample_R1.fa.gz --right sample_R2.fa.gz \
    --outdir results/sample1 --threads 16 -- -revcomp-right -mem 32

  # Nanopore cDNA reads
  scripts/run_rnabloom2.sh --long ont_reads.fa.gz --outdir results/ont1 --threads 16
EOF
}

FORCE=false
while (($#)); do
  case "$1" in
    --single) MODE="single"; READ1="${2:?--single requires a file}"; shift 2 ;;
    --left) MODE="paired"; READ1="${2:?--left requires a file}"; shift 2 ;;
    --right) READ2="${2:?--right requires a file}"; shift 2 ;;
    --long) MODE="long"; READ1="${2:?--long requires a file}"; shift 2 ;;
    --outdir) OUTDIR="${2:?--outdir requires a directory}"; shift 2 ;;
    --threads) THREADS="${2:?--threads requires an integer}"; shift 2 ;;
    --force) FORCE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; EXTRA=("$@"); break ;;
    *) echo "Error: unrecognized option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$MODE" && -n "$READ1" && -n "$OUTDIR" ]] || { echo "Error: input mode and --outdir are required." >&2; usage >&2; exit 2; }
[[ "$THREADS" =~ ^[1-9][0-9]*$ ]] || { echo "Error: --threads must be a positive integer." >&2; exit 2; }
[[ -f "$READ1" ]] || { echo "Error: input file not found: $READ1" >&2; exit 2; }
if [[ "$MODE" == "paired" ]]; then
  [[ -n "$READ2" ]] || { echo "Error: --left requires --right." >&2; exit 2; }
  [[ -f "$READ2" ]] || { echo "Error: input file not found: $READ2" >&2; exit 2; }
elif [[ -n "$READ2" ]]; then
  echo "Error: --right may only be used with --left." >&2
  exit 2
fi

if [[ -d "$OUTDIR" ]] && [[ -n "$(find "$OUTDIR" -mindepth 1 -maxdepth 1 -print -quit)" ]] && ! "$FORCE"; then
  echo "Error: output directory exists and is not empty: $OUTDIR" >&2
  echo "Choose a new directory or add --force if overwriting is intended." >&2
  exit 2
fi

if ! command -v rnabloom >/dev/null 2>&1; then
  echo "Error: rnabloom is not on PATH. Activate the environment that provides RNA-Bloom2 and try again." >&2
  exit 127
fi

case "$MODE" in
  single) INPUT_ARGS=(-sef "$READ1") ;;
  paired) INPUT_ARGS=(-left "$READ1" -right "$READ2") ;;
  long) INPUT_ARGS=(-long "$READ1") ;;
esac

echo "Running RNA-Bloom2 in: $OUTDIR"
rnabloom \
  "${INPUT_ARGS[@]}" -t "$THREADS" -outdir "$OUTDIR" "${EXTRA[@]}"
