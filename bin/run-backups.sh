#!/bin/bash
# bin/run-backups.sh

# Check if git-repositories-to-backup.txt exists
if [ ! -f git-repositories-to-backup.txt ]; then
  echo "Error: git-repositories-to-backup.txt not found."
  exit 1
fi

# Update Git repositories
echo "Updating Git repositories..."
while IFS= read -r repo_dir || [ -n "$repo_dir" ]; do
  # Skip empty lines and comments
  if [[ -z "$repo_dir" ]] || [[ "$repo_dir" =~ ^# ]]; then
    continue
  fi

  if [ -d "$repo_dir" ]; then
    echo "Pulling latest changes in $repo_dir..."
    cd "$repo_dir" || { echo "Failed to enter directory $repo_dir"; continue; }
    git pull
    cd - >/dev/null || exit 1
  else
    echo "Directory $repo_dir does not exist. Skipping."
  fi
done < git-repositories-to-backup.txt

# Run refresh-figma.sh
if [ -f ./bin/refresh-figma.sh ]; then
  echo "Running refresh-figma.sh..."
  ./bin/refresh-figma.sh
else
  echo "Error: refresh-figma.sh not found."
  exit 1
fi

# Run refresh-es2-dev-bkup.sh
if [ -f ./bin/refresh-es2-dev-bkup.sh ]; then
  echo "Running refresh-es2-dev-bkup.sh..."
  ./bin/refresh-es2-dev-bkup.sh
else
  echo "Error: refresh-es2-dev-bkup.sh not found."
  exit 1
fi

# Run refresh-aws-configuration-bkup.sh
if [ -f ./bin/refresh-aws-configuration-bkup.sh ]; then
  echo "Running refresh-aws-configuration-bkup.sh..."
  ./bin/refresh-aws-configuration-bkup.sh
else
  echo "Error: refresh-aws-configuration-bkup.sh not found."
  exit 1
fi

# Check if non-git-repo-directories-to-backup.txt exists
if [ ! -f non-git-repo-directories-to-backup.txt ]; then
  echo "Error: non-git-repo-directories-to-backup.txt not found."
  exit 1
fi

# Backup non-Git directories to S3
echo "Backing up non-Git directories to S3..."
while IFS= read -r backup_dir || [ -n "$backup_dir" ]; do
  # Skip empty lines and comments
  if [[ -z "$backup_dir" ]] || [[ "$backup_dir" =~ ^# ]]; then
    continue
  fi

  if [ -d "$backup_dir" ]; then
    echo "Backing up $backup_dir..."
    ./bin/s3-put.sh "$backup_dir"
  else
    echo "Directory $backup_dir does not exist. Skipping."
  fi
done < non-git-repo-directories-to-backup.txt

echo "All tasks completed successfully."
