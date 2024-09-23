#!/bin/bash
set -e

# Set variables
DESTINATION_DIR="$(pwd)"
SOURCE_BUCKET="primary-backup-1"
REPO_NAME="es2-esp32-arduino-aws"
ROLE_ARN="arn:aws:iam::127214154570:role/EC2-S3-Backup-Role"  # Replace with your IAM role ARN if different

# Assume the IAM role
echo "Assuming IAM role..."
temp_role=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "S3DownloadSession")

if [ $? -ne 0 ]; then
    echo "Failed to assume role. Please check your IAM role configuration."
    exit 1
fi

# Extract the temporary credentials
export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)

# Check if credentials were successfully obtained
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
    echo "Failed to extract temporary credentials. Please check your IAM role permissions."
    exit 1
fi

# Verify the bucket exists
echo "Verifying S3 bucket..."
if ! aws s3 ls "s3://$SOURCE_BUCKET" > /dev/null 2>&1; then
    echo "Error: Bucket $SOURCE_BUCKET does not exist or is not accessible."
    exit 1
fi

# Sync the repository from S3 to the local directory
echo "Starting sync from S3..."
aws s3 sync s3://$SOURCE_BUCKET/$REPO_NAME/ $DESTINATION_DIR --delete

# Check if sync was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to sync from S3. Please check your permissions and network connection."
    exit 1
fi

# Unset the temporary credentials
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "Download of $REPO_NAME from $SOURCE_BUCKET completed successfully"

