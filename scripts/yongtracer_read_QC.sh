#!/bin/bash
echo "script start: download and initial sequencing read quality control"
date
######commands start##########
sqlite3 -noheader -csv /shared/home/yongtracer/medbioinfo_folder/pascal/central_database/sample_collab.db "SELECT run_accession FROM sample_annot LEFT JOIN sample2bioinformatician ON sample_annot.patient_code = sample2bioinformatician.patient_code WHERE username = 'yongtracer'; " > /shared/home/yongtracer/medbioinfo_folder/tracer/MedBioinfo/analyses/yongtracer_run_accessions.txt
mkdir ../data/sra_fastq





#####commands end###########
date
echo "script end."

