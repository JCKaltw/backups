#!/bin/bash

# Set variables
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="/home/chris/projects/backups/aws-configurations"

AWS_REGION=$(aws configure get region)

# Check if a region is set
if [ -z "$AWS_REGION" ]; then
    echo "No default region found. Please set a default region using 'aws configure' or specify a region using the --region option."
    exit 1
fi

echo "Using AWS Region: $AWS_REGION"

# Create backup directory
mkdir -p $BACKUP_DIR

# EC2
aws ec2 describe-instances --region $AWS_REGION > $BACKUP_DIR/ec2_instances.json

# DynamoDB
aws dynamodb list-tables --region $AWS_REGION > $BACKUP_DIR/dynamodb_tables.json
for table in $(aws dynamodb list-tables --region $AWS_REGION --output text --query 'TableNames[]')
do
    aws dynamodb describe-table --table-name $table --region $AWS_REGION > $BACKUP_DIR/dynamodb_${table}.json
done

# Route53
aws route53 list-hosted-zones > $BACKUP_DIR/route53_zones.json

# RDS
aws rds describe-db-instances --region $AWS_REGION > $BACKUP_DIR/rds_instances.json

# IoT Core MQTT
aws iot describe-endpoint --endpoint-type iot:Data-ATS --region $AWS_REGION > $BACKUP_DIR/iot_endpoint.json
aws iot list-things --region $AWS_REGION > $BACKUP_DIR/iot_things.json

# Lambda
aws lambda list-functions --region $AWS_REGION > $BACKUP_DIR/lambda_functions.json

# API Gateway
aws apigateway get-rest-apis --region $AWS_REGION > $BACKUP_DIR/api_gateway.json

# IAM
aws iam list-users > $BACKUP_DIR/iam_users.json
aws iam list-roles > $BACKUP_DIR/iam_roles.json
aws iam list-policies --scope Local > $BACKUP_DIR/iam_policies.json

# Amazon Timestream
aws timestream-write list-databases --region $AWS_REGION > $BACKUP_DIR/timestream_databases.json

echo "Backup completed on $DATE for region $AWS_REGION"
