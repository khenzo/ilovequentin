# Deploy Hugo Blog to AWS Amplify using CLI

## Prerequisites
- AWS CLI configured (✅ Already done)
- GitHub Personal Access Token with `repo` scope

## Step 1: Set Environment Variables

```powershell
# PowerShell (Windows)
$APP_NAME = "ilovequentin"
$GITHUB_REPO = "https://github.com/khenzo/ilovequentin"
$BRANCH_NAME = "master"
$DOMAIN_NAME = "ilovequentin.it"
$REGION = "us-east-1"
$GITHUB_TOKEN = "YOUR_GITHUB_TOKEN_HERE"  # Replace with your token
```

Or in Git Bash:
```bash
# Git Bash / Linux
export APP_NAME="ilovequentin"
export GITHUB_REPO="https://github.com/khenzo/ilovequentin"
export BRANCH_NAME="master"
export DOMAIN_NAME="ilovequentin.it"
export REGION="us-east-1"
export GITHUB_TOKEN="YOUR_GITHUB_TOKEN_HERE"  # Replace with your token
```

## Step 2: Create Amplify App

```bash
aws amplify create-app \
  --name $APP_NAME \
  --description "Hugo blog - ilovequentin.it" \
  --repository $GITHUB_REPO \
  --access-token $GITHUB_TOKEN \
  --enable-branch-auto-build \
  --platform WEB \
  --region $REGION
```

**Save the `appId` from the output!** It looks like: `d3xxxxxxxxxx`

## Step 3: Update Build Configuration

```bash
# Set your APP_ID from step 2
export APP_ID="d3xxxxxxxxxx"  # Replace with your actual app ID

# Update with build spec
aws amplify update-app \
  --app-id $APP_ID \
  --build-spec file://amplify.yml \
  --region $REGION
```

## Step 4: Create Branch Connection

```bash
aws amplify create-branch \
  --app-id $APP_ID \
  --branch-name $BRANCH_NAME \
  --enable-auto-build \
  --region $REGION
```

## Step 5: Start First Deployment

```bash
aws amplify start-job \
  --app-id $APP_ID \
  --branch-name $BRANCH_NAME \
  --job-type RELEASE \
  --region $REGION
```

## Step 6: Get Your Site URL

```bash
aws amplify get-app \
  --app-id $APP_ID \
  --region $REGION \
  --query 'app.defaultDomain' \
  --output text
```

Your site will be at: `https://master.[default-domain]`

## Step 7: Add Custom Domain (Optional)

First, find your Route53 hosted zone:
```bash
aws route53 list-hosted-zones-by-name \
  --dns-name $DOMAIN_NAME \
  --query "HostedZones[?Name=='${DOMAIN_NAME}.'].Id" \
  --output text
```

Then add the domain to Amplify:
```bash
aws amplify create-domain-association \
  --app-id $APP_ID \
  --domain-name $DOMAIN_NAME \
  --enable-auto-sub-domain \
  --sub-domain-settings prefix=,branchName=$BRANCH_NAME prefix=www,branchName=$BRANCH_NAME \
  --region $REGION
```

This will:
- Create a free SSL certificate
- Configure CloudFront CDN
- Update Route53 DNS records automatically

## Step 8: Check Deployment Status

```bash
# List all jobs
aws amplify list-jobs \
  --app-id $APP_ID \
  --branch-name $BRANCH_NAME \
  --region $REGION

# Get specific job details (use jobId from previous command)
aws amplify get-job \
  --app-id $APP_ID \
  --branch-name $BRANCH_NAME \
  --job-id [JOB_ID] \
  --region $REGION
```

## Step 9: Check Domain Status

```bash
aws amplify get-domain-association \
  --app-id $APP_ID \
  --domain-name $DOMAIN_NAME \
  --region $REGION
```

Look for `domainStatus: AVAILABLE` - this means SSL is configured and DNS is ready!

---

## Quick Commands Reference

### View App Details
```bash
aws amplify get-app --app-id $APP_ID --region $REGION
```

### Trigger Manual Deployment
```bash
aws amplify start-job \
  --app-id $APP_ID \
  --branch-name $BRANCH_NAME \
  --job-type RELEASE \
  --region $REGION
```

### Update Build Settings
```bash
aws amplify update-app \
  --app-id $APP_ID \
  --build-spec file://amplify.yml \
  --region $REGION
```

### Delete App (if needed)
```bash
aws amplify delete-app --app-id $APP_ID --region $REGION
```

---

## Troubleshooting

### Check build logs in console
```
https://console.aws.amazon.com/amplify/home?region=us-east-1#/$APP_ID
```

### Common Issues

1. **"Access token is invalid"**: Your GitHub token needs `repo` scope
2. **"Branch not found"**: Make sure you've pushed to GitHub
3. **"Build failed"**: Check the build logs in the Amplify console
4. **Domain not found**: Ensure domain exists in Route53 first

---

## Cost Estimate
- Build minutes: 1000 free/month
- Storage: 15 GB free/month
- Data transfer: 100 GB free/month
- SSL Certificate: FREE
- **Expected monthly cost: $0.50-2**
