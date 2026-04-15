
# BM Souporcell Pipeline

This directory contains the scripts used to prepare sciCoCnT BAM files from four bone marrow samples and run [Souporcell](https://github.com/wheaton5/souporcell) for donor deconvolution.

Samples included in this run:

- `PR001798`
- `PR001799`
- `PR001855`
- `PR001856`

## Files

- `run_prepare_bam_PR001798.sh`
- `run_prepare_bam_PR001799.sh`
- `run_prepare_bam_PR001855.sh`
- `run_prepare_bam_PR001856.sh`
  Preprocess per-sample BAM files: remove duplicates, add read-group style tags, merge, sort, and index.
- `run_prepare_barcode.R`
  Builds an `ArchRProject`, merges sample metadata, and exports the cell barcode whitelist used by Souporcell.
- `run_souporcell_PR001798_PR001799_PR001855_PR001856.sh`
  Merges the per-sample BAMs and runs Souporcell with `k=4`.

## Input data

Per-sample BAM inputs are expected under, which is not included in this repo:

- `../../data/Janssens_Lab_Data/PR001798_sciCoCnT_JAND_DNA_ALIGNMENT_WELLID_BARCODES/BED`
- `../../data/Janssens_Lab_Data/PR001799_sciCoCnT_JAND_DNA_ALIGNMENT_WELLID_BARCODES/BED`
- `../../data/Janssens_Lab_Data/PR001855_sciCoCnT_JAND_DNA_ALIGNMENT_WELLID_BARCODES/BED`
- `../../data/Janssens_Lab_Data/PR001856_sciCoCnT_JAND_DNA_ALIGNMENT_WELLID_BARCODES/BED`

Additional required inputs:

- Sample sheets:
  `../../data/sample_sheet_PR001798.tsv`,
  `../../data/sample_sheet_PR001799.tsv`,
  `../../data/sample_sheet_PR001855.tsv`,
  `../../data/sample_sheet_PR001856.tsv`
- Arrow files from `../run_BM_coCnT_create_arrow/`, which can be downloaded from Zenodo (TODO: add link)
- Reference FASTA: `../../data/ref_genome/hg38_gencode.fa`, which is not included in this repo.
- Tagging helper: `../../lib/bin/bin_add_tags.py`

## Software requirements

- `samtools`
- `python`
- `R`
- R packages:
  `data.table`, `ggplot2`, `ggpubr`, `plyr`, `magrittr`, `readr`, `stringr`, `ggsci`, `ArchR`
- Conda environment `SouporCell` with `souporcell_pipeline.py`

## Workflow

Run the pipeline in this order.

### 1. Prepare BAMs for each sample

Submit the four per-sample jobs:

```bash
bash run_prepare_bam_PR001798.sh
bash run_prepare_bam_PR001799.sh
bash run_prepare_bam_PR001855.sh
bash run_prepare_bam_PR001856.sh
```

Each script does the following:

1. Iterates over all BAM files in the sample `BED` directory.
2. Removes duplicates with `samtools fixmate` and `samtools markdup` using the `CB` barcode tag.
3. Adds tags/read-group related information with `../../lib/bin/bin_add_tags.py`.
4. Merges per-sample BAMs into `merged.bam`.
5. Sorts and indexes the final file as `merged.sorted.bam`.

Per-sample outputs are written to:

- `tmp/PR001798_bam/`
- `tmp/PR001799_bam/`
- `tmp/PR001855_bam/`
- `tmp/PR001856_bam/`

Main output file per sample:

- `tmp/<sample>_bam/merged.sorted.bam`

### 2. Prepare barcode whitelist and metadata

Run:

```bash
Rscript run_prepare_barcode.R
```

This script:

1. Loads all four sample sheets.
2. Opens Arrow files from `../run_BM_coCnT_create_arrow/`.
3. Creates an `ArchRProject` using genome `hg38`.
4. Merges project metadata with the sample sheet.
5. Exports combined metadata and a cell barcode whitelist.

Outputs:

- `tmp/cell_metadata_4.tsv`
- `tmp/cell_barcode_PR001798_PR001799_PR001855_PR001856.tsv`

Barcode selection currently keeps cells with `nFrags > 250`.

### 3. Run Souporcell on the merged 4-sample BAM

Submit:

```bash
bash run_souporcell_PR001798_PR001799_PR001855_PR001856.sh
```

This script is set up to:

1. Use the per-sample merged BAMs from `tmp/*_bam/merged.bam`.
2. Merge them into a combined BAM.
3. Sort and index the merged BAM.
4. Run Souporcell with:
   `-k 4`, `--no_umi True`, `--skip_remap True`, `--ignore True`

Souporcell output directory:

- `tmp/PR001798_PR001799_PR001855_PR001856_souporcell_output/`

## Current generated outputs

The output of Souporcell will be added to this directory as `./tmp/PR001798_PR001799_PR001855_PR001856_souporcell_output/`

The main output file is `clusters.tsv`, which contains the cluster assignment for each cell barcode. This file is used in downstream analyses to assign cells to donors and evaluate the performance of Souporcell.

