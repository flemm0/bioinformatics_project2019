set -e
cd /Users/candicewu/bash_project/master_file

echo "Combining reference sequences..."
cat ./ref_sequences/hsp*.fasta > hsp70combined.fasta
cat ./ref_sequences/m*.fasta > mcra.combined.fasta

echo "Aligning sequences..."
muscle -in hsp70combined.fasta -out hsp70muscled.fasta
muscle -in mcracombined.fasta -out mcramuscled.fasta

echo "Building hmm profiles..."
hmmbuild hsp70.hmm hsp70muscled.fasta
hmmbuild mcra.hmm mcramuscled.fasta

mkdir -p ./mcra-present

echo "Finding McrA present Archaea..."
for proteome in proteomes/*.fasta
do
	basenum=$(basename ${proteome#*_} .fasta)
	hmmsearch --tblout mcra_${basenum}.txt mcra.hmm proteomes/proteome_${basenum}.fasta
	
	mcra=$(grep -v "#" mcra_${basenum}.txt | wc -l)
	
	if [ $mcra -gt 0 ]; then
		cp -p proteomes/proteome_${basenum}.fasta mcra-present/
	fi
	rm mcra_${basenum}.txt
done

echo "Finding HSP70 present Archaea..."
for proteome in mcra-present/*.fasta
do
	basenum=$(basename ${proteome#*_} .fasta)
	hmmsearch --tblout hsp70_${basenum}.txt hsp70.hmm mcra-present/proteome_${basenum}.fasta

	hsp70=$(grep -v "#" hsp70_${basenum}.txt | uniq | wc -l)

	if [ $hsp70 -gt 0 ];
	then
		echo "proteome_${basenum}"," $hsp70" >> candidates.txt
	fi
	
	rm hsp70_${basenum}.txt
done

echo "Sorting final candidates from best to worst..."
sort -r -k 2 candidates.txt

ls candidates.txt
