#!/bin/bash

current_date=$(date)

# Capture the start time
start_time=$(date +%s)

# Input and output files
default_input_file="test_bulk.sh"
default_output_file="temp_output_ProjectsCodesAndCounts.txt"

# Assign variables from input arguments or use defaults
input_file="${1:-$default_input_file}"
output_file="${2:-$default_output_file}"

echo "$current_date"

#Add line to the file so the last project will be added too to the outputfile
echo "end_file" >> "$input_file"

if [ ! -f "$output_file" ]; then
    touch "$output_file"
fi

#echo "Project_name	Project_code	num_samples_in_OTS" > "$output_file"
#num_lines=$(($(wc -l "$input_file")-1))
num_lines=$(($(wc -l < "$input_file") - 1))
i=0

# Clear the output file if it exists
> "$output_file"

project_name="Project_name	PRJ_code	GEO_code	num_samples	OTS_samples_codes" # $(head -1 $input_file | awk -F "/" '{print $6}')
samples_count=""
OTS_samples_codes=()
# Loop through each line of the input file
while IFS= read -r line; do
    echo -ne "$i/$num_lines\r"
    sleep 1
    i=$((i + 1))
    if [ "$(echo "$line" | awk -F "/" '{print $6}')" = "$project_name" ]; then
	#echo "$project_name"
	samples_count=$((samples_count + 1))
	srr_code=$(echo "$line" | awk -F "/" '{print $8}' | awk -F "_" '{print $1}')
	OTS_samples_codes+=("$srr_code")
    else
	prj_code=$(curl -s "https://www.ncbi.nlm.nih.gov/sra/?term=$srr_code&report=FullXml" | grep -oP 'PRJ[^<]+' | awk -F';' '{print $1}' | head -1)
        geo_code=$(curl -s "https://www.ncbi.nlm.nih.gov/sra/?term=$srr_code&report=FullXml" | grep -oP 'GSE[^<]+' | awk -F';' '{print $1}' | head -1)

	if [ -z "$geo_code" ] && [ "$i" -gt 1 ]; then
	    geo_code="Null"
	fi
	echo -e "$project_name\t$prj_code\t$geo_code\t$samples_count\t$OTS_samples_codes" >> "$output_file"
	#echo -e "$project_name\t$prj_code\t$samples_count"

	samples_count=1
	project_name=$(echo "$line" | awk -F "/" '{print $6}')

	# Extract the SRR code from the line
	srr_code=$(echo "$line" | awk -F "/" '{print $8}' | awk -F "_" '{print $1}')
	OTS_samples_codes=("$srr_code")
	# Fetch the PRJ code using curl and grep
	#prj_code=$(curl -s "https://www.ncbi.nlm.nih.gov/sra/?term=$srr_code&report=FullXml" | grep -oP 'PRJ[^<]+' | awk -F';' '{print $1}' | head -)1

    fi

done < "$input_file"

#Delete the last line that i add
head -n -1 "$input_file" > temp_input.txt && mv temp_input.txt "$input_file"

# Capture the end time
end_time=$(date +%s)
# Calculate the elapsed time
elapsed_time=$((end_time - start_time))

# Print the elapsed time
echo "Running time: $(($elapsed_time/60))  minutes ($elapsed_time seconds)"

# Notify the user that the script has finished
echo "PRJ codes have been saved to $output_file."

