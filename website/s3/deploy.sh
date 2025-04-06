#!/bin/bash
#
# MacMonitor Website - S3 Deployment Script
# This script deploys the MacMonitor website to Amazon S3
#
# Prerequisites:
# - AWS CLI installed: https://aws.amazon.com/cli/
# - AWS credentials configured with S3 permissions
#

# Set strict error handling
set -e

# Configuration
WEBSITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_PROFILE="default"
S3_BUCKET="macmonitor.axiracode.com"
REGION="us-east-1"

# AWS credentials from file
echo "Loading AWS credentials from temporary file..."
source /tmp/aws_credentials.sh

# Functions
check_dependencies() {
  if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first:"
    echo "https://aws.amazon.com/cli/"
    exit 1
  fi
}

deploy_website() {
  echo "Deploying website to S3..."
  
  # Create bucket
  echo "Creating bucket $S3_BUCKET..."
  aws s3 mb s3://$S3_BUCKET --region $REGION
  
  # Configure bucket for static website hosting
  echo "Configuring bucket for static website hosting..."
  aws s3 website s3://$S3_BUCKET --index-document index.html --error-document error.html
  
  # Sync website files to S3 without ACLs
  echo "Uploading website files..."
  aws s3 sync "$WEBSITE_DIR" s3://$S3_BUCKET \
    --exclude "s3/*" \
    --exclude ".git/*" \
    --exclude "node_modules/*" \
    --exclude ".DS_Store" \
    --exclude "*.sh" \
    --delete \
    --cache-control "max-age=3600"

  # Set appropriate content types and cache control for specific file types
  echo "Setting appropriate headers for HTML files..."
  find "$WEBSITE_DIR" -name "*.html" | while read -r file; do
    relative_path="${file#$WEBSITE_DIR/}"
    aws s3 cp "$file" s3://$S3_BUCKET/$relative_path \
      --content-type "text/html; charset=utf-8" \
      --cache-control "max-age=3600"
  done

  echo "Setting appropriate headers for CSS files..."
  find "$WEBSITE_DIR" -name "*.css" | while read -r file; do
    relative_path="${file#$WEBSITE_DIR/}"
    aws s3 cp "$file" s3://$S3_BUCKET/$relative_path \
      --content-type "text/css" \
      --cache-control "max-age=604800"
  done

  echo "Setting appropriate headers for JavaScript files..."
  find "$WEBSITE_DIR" -name "*.js" | while read -r file; do
    relative_path="${file#$WEBSITE_DIR/}"
    aws s3 cp "$file" s3://$S3_BUCKET/$relative_path \
      --content-type "application/javascript" \
      --cache-control "max-age=604800"
  done

  echo "Setting appropriate headers for image files..."
  find "$WEBSITE_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" | while read -r file; do
    if [ -f "$file" ]; then
      relative_path="${file#$WEBSITE_DIR/}"
      extension="${file##*.}"
      content_type="image/$extension"
      if [ "$extension" = "svg" ]; then
        content_type="image/svg+xml"
      fi
      aws s3 cp "$file" s3://$S3_BUCKET/$relative_path \
        --content-type "$content_type" \
        --cache-control "max-age=2592000"
    fi
  done
  
  # Try to set the bucket policy (this may fail if account settings block public access)
  echo "Attempting to set bucket policy to allow public access..."
  cat > /tmp/bucket-policy.json << EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"PublicReadGetObject",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::$S3_BUCKET/*"]
    }
  ]
}
EOF
  if aws s3api put-bucket-policy --bucket $S3_BUCKET --policy file:///tmp/bucket-policy.json; then
    echo "Successfully set bucket policy!"
  else
    echo "Could not set bucket policy - you may need to configure this manually in the AWS Console."
  fi
  rm /tmp/bucket-policy.json
  
  echo ""
  echo "===== DEPLOYMENT COMPLETED ====="
  echo ""
  echo "Bucket name: $S3_BUCKET"
  echo "Website URL: http://$S3_BUCKET.s3-website-$REGION.amazonaws.com/"
  echo ""
  echo "IMPORTANT: To make the website publicly accessible, you need to:"
  echo "1. Go to the AWS S3 Console: https://s3.console.aws.amazon.com/"
  echo "2. Select bucket: $S3_BUCKET"
  echo "3. Go to the 'Permissions' tab"
  echo "4. Edit 'Block public access' settings and disable all blocks"
  echo "5. Under 'Bucket policy', add a policy allowing public read access"
  echo ""
  echo "Example bucket policy:"
  echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::'$S3_BUCKET'/*"
    }
  ]
}'
}

# Main
check_dependencies
deploy_website
