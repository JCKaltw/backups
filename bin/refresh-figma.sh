#!/bin/bash

# Source the virtual environment
source ./source-venv.sh

# Run the Python script
python src/refresh-figma-work.py

# Directory containing the backups
backup_dir="figma_backups"

# Compress any non-gzipped JSON files in the backup directory
echo "Compressing uncompressed JSON files in $backup_dir..."
for file in "$backup_dir"/*.json; do
  if [ -f "$file" ]; then
    echo "Compressing $file..."
    gzip -9 "$file"
  fi
done

# Get the current month in YYYYMM format
current_month=$(date +"%Y%m")

# Declare an associative array to hold files grouped by month
declare -A files_by_month

# Collect files grouped by their month (excluding the current month)
echo "Grouping files by month (excluding current month: $current_month)..."
for file in "$backup_dir"/figma_backup_*.json.gz; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    # Extract the date part from the filename
    # Filename format: figma_backup_<id>_<YYYYMMDD>_<HHMMSS>.json.gz
    # Example: figma_backup_yjrGmErueQtZgLdPq18Qvo_20240923_172034.json.gz
    IFS='_' read -r -a fields <<< "$filename"
    date_part=${fields[3]}     # Extract YYYYMMDD
    month=${date_part:0:6}     # Extract YYYYMM
    if [[ "$month" != "$current_month" ]]; then
      files_by_month["$month"]+="$file "
    fi
  fi
done

# For each month, delete all but the last file
echo "Cleaning up old backups..."
for month in "${!files_by_month[@]}"; do
  files="${files_by_month[$month]}"
  # Convert the string of files into an array
  read -r -a file_array <<< "$files"
  # Sort the files to find the last one (latest)
  sorted_files=($(printf '%s\n' "${file_array[@]}" | sort))
  last_file="${sorted_files[-1]}"
  echo "For month $month, keeping the most recent backup: $(basename "$last_file")"
  for f in "${file_array[@]}"; do
    if [[ "$f" != "$last_file" ]]; then
      echo "Deleting old backup: $(basename "$f")"
      rm "$f"
    fi
  done
done

echo "Backup directory cleanup complete."

