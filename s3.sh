#!/bin/bash
set -e

# Set variables
REPOSITORIES=(
    "/home/chris/projects/es2"
    "/home/chris/projects/es2-esp32-arduino-aws"
)
DESTINATION_BUCKET="primary-backup-1"
ROLE_ARN="arn:aws:iam::127214154570:role/EC2-S3-Backup-Role"

# Assume the IAM role
echo "Assuming IAM role..."
temp_role=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "S3BackupSession")

if [ $? -ne 0 ]; then
    echo "Failed to assume role. Please check your IAM role configuration."
    exit 1
fi

# Extract the temporary credentials
export AWS_ACCESS_KEY_ID=$(echo "$temp_role" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$temp_role" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$temp_role" | jq -r .Credentials.SessionToken)

# Check if credentials were successfully obtained
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
    echo "Failed to extract temporary credentials. Please check your IAM role permissions."
    exit 1
fi

# Verify the bucket exists
echo "Verifying S3 bucket..."
if ! aws s3 ls "s3://$DESTINATION_BUCKET" > /dev/null 2>&1; then
    echo "Error: Bucket $DESTINATION_BUCKET does not exist or is not accessible."
    exit 1
fi

# Sync each repository
for SOURCE_REPO in "${REPOSITORIES[@]}"; do
    REPO_NAME=$(basename "$SOURCE_REPO")
    echo "Starting sync of $REPO_NAME to S3..."

    cd $SOURCE_REPO && git pull

    aws s3 sync "$SOURCE_REPO" "s3://$DESTINATION_BUCKET/$REPO_NAME/" --delete

    # Check if sync was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to sync $REPO_NAME to S3. Please check your permissions and network connection."
        exit 1
    fi
    echo "Backup of $REPO_NAME to $DESTINATION_BUCKET completed successfully"
done

# Unset the temporary credentials
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "All backups completed successfully"
