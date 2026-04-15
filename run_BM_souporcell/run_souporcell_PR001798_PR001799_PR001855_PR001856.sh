#!/usr/bin/env bash
#SBATCH -J souporcell_4
#SBATCH -o sort_%j.out         # Standard output (%j = job ID)
#SBATCH -e sort_%j.err         # Standard error
#SBATCH -c 40                  # Number of CPU cores
#SBATCH --mem=400G             # Memory limit
#SBATCH -t 12:00:00            # Time limit (hh:mm:ss)
#SBATCH --mail-type=END,FAIL   # (optional) email notifications
#SBATCH --mail-user=wenjie.sun@vai.org
set -euo pipefail

threads=35

out_dir="./tmp/PR001799_PR001798_PR001855_PR001856_souporcell_output/"
mkdir -p "$out_dir"

## Join two BAM files
bam1="./tmp/PR001798_bam/merged.bam"
bam2="./tmp/PR001799_bam/merged.bam"
bam3="./tmp/PR001855_bam/merged.bam"
bam4="./tmp/PR001856_bam/merged.bam"

## Merge all BAM files into one
# samtools merge -@ $threads -1 -f "${out_dir}/merged.bam" $bam1 $bam2 $bam3 $bam4

## Sort and index the merged BAM file
# samtools sort -m 11G -@ $threads -T ./tmp/PR001799_PR001798_PR001855_PR001856_souporcell_output/ -o "${out_dir}/merged.sorted.bam" "${out_dir}/merged.bam"
# samtools index -@ $threads "${out_dir}/merged.sorted.bam"

## Remove the unsorted merged BAM file to save space
# rm "${out_dir}/merged.bam"

## SouporCell
## Install conda env
## conda create -n SouporCell bioconda::souporcell
conda run -n SouporCell souporcell_pipeline.py \
    -i "${out_dir}/merged.sorted.bam" \
    -b "./tmp/cell_barcode_PR001798_PR001799_PR001855_PR001856.tsv \
    -f "../../data/ref_genome/hg38_gencode.fa" \
    -t $threads \
    -k 4 \
    --no_umi True --skip_remap True --ignore True \
    -o ./tmp/PR001798_PR001799_PR001855_PR001856_souporcell_output/ 

# conda run -n SouporCell souporcell_pipeline.py \
#     -i "${out_dir}/merged.sorted.bam" \
#     -b "../run_BM_bed_profile/tmp/cell_barcode_km.tsv" \
#     -f "../../data/ref_genome/hg38_gencode.fa" \
#     -t $threads \
#     -k 4 \
#     --no_umi True --skip_remap True --ignore True \
#     -o ./tmp/souporcell_output_km/ 
