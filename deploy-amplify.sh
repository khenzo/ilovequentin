#!/bin/bash

# AWS Amplify Deployment Script for Hugo Blog
# This script creates and configures an AWS Amplify app for ilovequentin.it

set -e  # Exit on error

echo "=========================================="
echo "AWS Amplify Deployment for ilovequentin.it"
echo "=========================================="
echo ""

# Configuration
APP_NAME="ilovequentin"
GITHUB_REPO="https://github.com/khenzo/ilovequentin"
GITHUB_OWNER="khenzo"
GITHUB_REPO_NAME="ilovequentin"
BRANCH_NAME="master"
DOMAIN_NAME="ilovequentin.it"
REGION="us-east-1"  # Required for Route53 and CloudFront

echo "📋 Configuration:"
echo "  App Name: $APP_NAME"
echo "  Repository: $GITHUB_REPO"
echo "  Branch: $BRANCH_NAME"
echo "  Domain: $DOMAIN_NAME"
echo "  Region: $REGION"
echo ""

# Prompt for GitHub token
read -sp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
echo ""
echo ""

# Step 1: Create Amplify App
echo "🚀 Step 1: Creating Amplify App..."
APP_ID=$(aws amplify create-app \
  --name "$APP_NAME" \
  --description "Hugo blog - ilovequentin.it" \
  --repository "$GITHUB_REPO" \
  --access-token "$GITHUB_TOKEN" \
  --enable-branch-auto-build \
  --enable-branch-auto-deletion \
  --enable-auto-branch-creation \
  --platform WEB \
  --region "$REGION" \
  --query 'app.appId' \
  --output text)

if [ -z "$APP_ID" ]; then
  echo "❌ Failed to create Amplify app"
  exit 1
fi

echo "✅ Amplify App created successfully!"
echo "   App ID: $APP_ID"
echo ""

# Step 2: Update app with build spec
echo "🔧 Step 2: Configuring build settings..."
BUILD_SPEC=$(cat amplify.yml)

aws amplify update-app \
  --app-id "$APP_ID" \
  --build-spec "$BUILD_SPEC" \
  --region "$REGION" \
  --no-cli-pager > /dev/null

echo "✅ Build settings configured"
echo ""

# Step 3: Create branch
echo "🌿 Step 3: Creating branch connection..."
BRANCH_ARN=$(aws amplify create-branch \
  --app-id "$APP_ID" \
  --branch-name "$BRANCH_NAME" \
  --enable-auto-build \
  --enable-pull-request-preview false \
  --region "$REGION" \
  --query 'branch.branchArn' \
  --output text)

echo "✅ Branch '$BRANCH_NAME' connected"
echo "   Branch ARN: $BRANCH_ARN"
echo ""

# Step 4: Start deployment
echo "🏗️  Step 4: Starting first deployment..."
JOB_ID=$(aws amplify start-job \
  --app-id "$APP_ID" \
  --branch-name "$BRANCH_NAME" \
  --job-type RELEASE \
  --region "$REGION" \
  --query 'jobSummary.jobId' \
  --output text)

echo "✅ Deployment started"
echo "   Job ID: $JOB_ID"
echo ""
echo "⏳ Building your site... This takes 2-3 minutes."
echo "   You can check progress at: https://console.aws.amazon.com/amplify/home?region=$REGION#/$APP_ID"
echo ""

# Wait for deployment to complete (optional)
echo "Waiting for deployment to complete..."
while true; do
  STATUS=$(aws amplify get-job \
    --app-id "$APP_ID" \
    --branch-name "$BRANCH_NAME" \
    --job-id "$JOB_ID" \
    --region "$REGION" \
    --query 'job.summary.status' \
    --output text)

  echo "   Current status: $STATUS"

  if [ "$STATUS" == "SUCCEED" ]; then
    echo "✅ Deployment completed successfully!"
    break
  elif [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "CANCELLED" ]; then
    echo "❌ Deployment failed with status: $STATUS"
    exit 1
  fi

  sleep 15
done
echo ""

# Step 5: Get the default domain
echo "🌐 Step 5: Getting default domain..."
DEFAULT_DOMAIN=$(aws amplify get-app \
  --app-id "$APP_ID" \
  --region "$REGION" \
  --query 'app.defaultDomain' \
  --output text)

echo "✅ Your site is live at: https://$BRANCH_NAME.$DEFAULT_DOMAIN"
echo ""

# Step 6: Add custom domain
echo "🔗 Step 6: Adding custom domain..."

# Check if domain exists in Route53
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$DOMAIN_NAME" \
  --query "HostedZones[?Name=='${DOMAIN_NAME}.'].Id" \
  --output text | cut -d'/' -f3)

if [ -z "$HOSTED_ZONE_ID" ]; then
  echo "⚠️  Warning: Domain $DOMAIN_NAME not found in Route53"
  echo "   Please add it to Route53 first, then run:"
  echo "   aws amplify create-domain-association --app-id $APP_ID --domain-name $DOMAIN_NAME --region $REGION"
else
  echo "   Found hosted zone: $HOSTED_ZONE_ID"

  # Create domain association
  aws amplify create-domain-association \
    --app-id "$APP_ID" \
    --domain-name "$DOMAIN_NAME" \
    --enable-auto-sub-domain \
    --sub-domain-settings "prefix=,branchName=$BRANCH_NAME" "prefix=www,branchName=$BRANCH_NAME" \
    --region "$REGION" \
    --no-cli-pager > /dev/null

  echo "✅ Custom domain added: $DOMAIN_NAME"
  echo "   Configuring DNS and SSL certificate... (this takes 5-15 minutes)"
  echo ""
fi

# Summary
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "🌐 Your site URLs:"
echo "   Default: https://$BRANCH_NAME.$DEFAULT_DOMAIN"
if [ ! -z "$HOSTED_ZONE_ID" ]; then
  echo "   Custom:  https://$DOMAIN_NAME (DNS propagating...)"
  echo "   WWW:     https://www.$DOMAIN_NAME (DNS propagating...)"
fi
echo ""
echo "📊 Amplify Console:"
echo "   https://console.aws.amazon.com/amplify/home?region=$REGION#/$APP_ID"
echo ""
echo "🔄 Future deployments:"
echo "   Just 'git push' to deploy automatically!"
echo ""
echo "⚙️  App ID (save this): $APP_ID"
echo ""
