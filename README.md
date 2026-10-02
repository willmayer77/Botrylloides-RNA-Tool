# RNA assembly tool

This repository starts the RNA-assembly workflow with RNA-Bloom2. It assumes
RNA-Bloom2 is already installed and that the `rnabloom` command is available
on your shell's `PATH` (for example, after activating its environment).

## Run an assembly

The launcher accepts FASTA or FASTQ reads (including `.gz` files) and invokes
the already-available `rnabloom` executable directly.

```bash
# Single-end reads
scripts/run_rnabloom2.sh --single inputs/reads.fa --outdir results/sample1 --threads 16

# Paired-end reads
scripts/run_rnabloom2.sh --left inputs/sample_R1.fa.gz --right inputs/sample_R2.fa.gz \
  --outdir results/sample1 --threads 16 -- -revcomp-right -mem 32

# Long reads
scripts/run_rnabloom2.sh --long inputs/ont_reads.fa.gz --outdir results/ont1 --threads 16
```

Place RNA-Bloom2-specific settings after `--`; they are passed through exactly
as written. Run `scripts/run_rnabloom2.sh --help` to see the supported wrapper
arguments. Typical output includes `rnabloom.transcripts.fa` and
`rnabloom.transcripts.nr.fa` (for short-read assembly).
