#!/bin/bash
echo "script start: download and initial sequencing read quality control"
date
######commands start##########
# extract accession number by left join sample_annot with sample2bioinformatician for myself
sqlite3 -noheader -csv /shared/home/yongtracer/medbioinfo_folder/pascal/central_database/sample_collab.db "SELECT run_accession FROM sample_annot LEFT JOIN sample2bioinformatician ON sample_annot.patient_code = sample2bioinformatician.patient_code WHERE username = 'yongtracer'; " > /shared/home/yongtracer/medbioinfo_folder/tracer/MedBioinfo/analyses/yongtracer_run_accessions.txt
mkdir ../data/sra_fastq
module load sra-tools

# Download FASTQ data according to extracted accession number
cat yongtracer_run_accessions.txt | srun --cpus-per-task=1 --time=00:3000 xargs fastq-dump --split-e --gzip --readids --outdir ../data/sra_fastq/ --disable-multithreading

# Quality contral with fastQC
mkdir /shared/home/yongtracer/medbioinfo_folder/tracer/MedBioinfo/analyses/fastqc
module load fastqc




#####commands end###########
date
echo "script end."

