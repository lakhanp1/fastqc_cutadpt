# fastqc_cutadpt

This Perl script runs `FastQC` program on input FASTA files, detects the overrepresented sequences from FastQC report and trims the sequences using `cutadapt` tool. `FastQC` is run again on the trimmed fastq files for comparison.


### Install

Download the `fastqc_cutadpt` folder and run as described below.

### Usage
```Perl
perl fqstqcCutadapt.pl -1 <R1.fastq.gz> -2 <R2.fastq.gz>
```

### Help

| Argument | Description |
| :------------- | :-------------------- |
| `-1` | R1 FASTQ file |
| `-2` | R2 FASTQ file |
| `--nofastqc` | [FLAG] First round of `FastQC` is skipped and `FastQC` result is read directly from `--fastqcOut` option. Default: FastQC is run. |
| `--adapters` | [STR] FASTA file with Illumina adapters. Default: *data/universal_adapters.fasta* |
| `--fastqcOut` | [STR] Directory to store the FastQc result. Default: *fastqc* |
| `--trimmedOut` | [STR] Path to store trimmed FASTQ files. Default: *fastq_trimmed* |
| `--help` | Show this scripts help information |


<br><br><br><br>
---

#### License
MIT
