# AWS Amplify Deployment Script for Hugo Blog (PowerShell)
# Run this in PowerShell to deploy your blog to AWS Amplify

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AWS Amplify Deployment for ilovequentin.it" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$APP_NAME = "ilovequentin"
$GITHUB_REPO = "https://github.com/khenzo/ilovequentin"
$BRANCH_NAME = "master"
$DOMAIN_NAME = "ilovequentin.it"
$REGION = "us-east-1"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  App Name: $APP_NAME"
Write-Host "  Repository: $GITHUB_REPO"
Write-Host "  Branch: $BRANCH_NAME"
Write-Host "  Domain: $DOMAIN_NAME"
Write-Host "  Region: $REGION"
Write-Host ""

# Prompt for GitHub token
$GITHUB_TOKEN = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
$GITHUB_TOKEN_PLAIN = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($GITHUB_TOKEN))
Write-Host ""

# Step 1: Create Amplify App
Write-Host "Step 1: Creating Amplify App..." -ForegroundColor Green
try {
    $appResult = aws amplify create-app `
        --name $APP_NAME `
        --description "Hugo blog - ilovequentin.it" `
        --repository $GITHUB_REPO `
        --access-token $GITHUB_TOKEN_PLAIN `
        --enable-branch-auto-build `
        --platform WEB `
        --region $REGION `
        --output json | ConvertFrom-Json

    $APP_ID = $appResult.app.appId
    Write-Host "Amplify App created successfully!" -ForegroundColor Green
    Write-Host "   App ID: $APP_ID" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "Failed to create Amplify app: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Update app with build spec
Write-Host "Step 2: Configuring build settings..." -ForegroundColor Green
try {
    $buildSpec = Get-Content -Path "amplify.yml" -Raw

    aws amplify update-app `
        --app-id $APP_ID `
        --build-spec $buildSpec `
        --region $REGION `
        --no-cli-pager | Out-Null

    Write-Host "Build settings configured" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "Failed to update build settings: $_" -ForegroundColor Red
}

# Step 3: Create branch
Write-Host "Step 3: Creating branch connection..." -ForegroundColor Green
try {
    $branchResult = aws amplify create-branch `
        --app-id $APP_ID `
        --branch-name $BRANCH_NAME `
        --enable-auto-build `
        --region $REGION `
        --output json | ConvertFrom-Json

    Write-Host "Branch '$BRANCH_NAME' connected" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "Failed to create branch: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Start deployment
Write-Host "Step 4: Starting first deployment..." -ForegroundColor Green
try {
    $jobResult = aws amplify start-job `
        --app-id $APP_ID `
        --branch-name $BRANCH_NAME `
        --job-type RELEASE `
        --region $REGION `
        --output json | ConvertFrom-Json

    $JOB_ID = $jobResult.jobSummary.jobId
    Write-Host "Deployment started" -ForegroundColor Green
    Write-Host "   Job ID: $JOB_ID" -ForegroundColor White
    Write-Host ""
    Write-Host "Building your site... This takes 2-3 minutes." -ForegroundColor Yellow
    Write-Host "   Console: https://console.aws.amazon.com/amplify/home?region=$REGION#/$APP_ID" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "Failed to start deployment: $_" -ForegroundColor Red
    exit 1
}

# Wait for deployment
Write-Host "Waiting for deployment to complete..." -ForegroundColor Yellow
$maxAttempts = 40  # 40 * 15 seconds = 10 minutes max
$attempt = 0

while ($attempt -lt $maxAttempts) {
    try {
        $jobStatus = aws amplify get-job `
            --app-id $APP_ID `
            --branch-name $BRANCH_NAME `
            --job-id $JOB_ID `
            --region $REGION `
            --output json | ConvertFrom-Json

        $status = $jobStatus.job.summary.status
        Write-Host "   Current status: $status" -ForegroundColor Gray

        if ($status -eq "SUCCEED") {
            Write-Host "Deployment completed successfully!" -ForegroundColor Green
            break
        }
        elseif ($status -eq "FAILED" -or $status -eq "CANCELLED") {
            Write-Host "Deployment failed with status: $status" -ForegroundColor Red
            exit 1
        }

        Start-Sleep -Seconds 15
        $attempt++
    }
    catch {
        Write-Host "Error checking job status: $_" -ForegroundColor Red
        break
    }
}
Write-Host ""

# Step 5: Get the default domain
Write-Host "Step 5: Getting default domain..." -ForegroundColor Green
try {
    $appInfo = aws amplify get-app `
        --app-id $APP_ID `
        --region $REGION `
        --output json | ConvertFrom-Json

    $DEFAULT_DOMAIN = $appInfo.app.defaultDomain
    Write-Host "Your site is live at: https://$BRANCH_NAME.$DEFAULT_DOMAIN" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "Failed to get default domain: $_" -ForegroundColor Red
}

# Step 6: Add custom domain
Write-Host "Step 6: Adding custom domain..." -ForegroundColor Green
try {
    # Check if domain exists in Route53
    $hostedZones = aws route53 list-hosted-zones-by-name `
        --dns-name $DOMAIN_NAME `
        --output json | ConvertFrom-Json

    $HOSTED_ZONE_ID = $null
    foreach ($zone in $hostedZones.HostedZones) {
        if ($zone.Name -eq "$DOMAIN_NAME.") {
            $HOSTED_ZONE_ID = $zone.Id.Split('/')[-1]
            break
        }
    }

    if ($null -eq $HOSTED_ZONE_ID) {
        Write-Host "Warning: Domain $DOMAIN_NAME not found in Route53" -ForegroundColor Yellow
        Write-Host "   Add it to Route53 first, then run:" -ForegroundColor Yellow
        Write-Host "   aws amplify create-domain-association --app-id $APP_ID --domain-name $DOMAIN_NAME --region $REGION" -ForegroundColor White
    }
    else {
        Write-Host "   Found hosted zone: $HOSTED_ZONE_ID" -ForegroundColor White

        # Create domain association
        aws amplify create-domain-association `
            --app-id $APP_ID `
            --domain-name $DOMAIN_NAME `
            --enable-auto-sub-domain `
            --sub-domain-settings "prefix=,branchName=$BRANCH_NAME" "prefix=www,branchName=$BRANCH_NAME" `
            --region $REGION `
            --no-cli-pager | Out-Null

        Write-Host "Custom domain added: $DOMAIN_NAME" -ForegroundColor Green
        Write-Host "   Configuring DNS and SSL certificate... (this takes 5-15 minutes)" -ForegroundColor Yellow
        Write-Host ""
    }
}
catch {
    Write-Host "Failed to add custom domain: $_" -ForegroundColor Yellow
    Write-Host "   You can add it manually later in the Amplify console" -ForegroundColor Yellow
}

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your site URLs:" -ForegroundColor Yellow
Write-Host "   Default: https://$BRANCH_NAME.$DEFAULT_DOMAIN" -ForegroundColor Cyan
if ($HOSTED_ZONE_ID) {
    Write-Host "   Custom:  https://$DOMAIN_NAME (DNS propagating...)" -ForegroundColor Cyan
    Write-Host "   WWW:     https://www.$DOMAIN_NAME (DNS propagating...)" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Amplify Console:" -ForegroundColor Yellow
Write-Host "   https://console.aws.amazon.com/amplify/home?region=$REGION#/$APP_ID" -ForegroundColor Cyan
Write-Host ""
Write-Host "Future deployments:" -ForegroundColor Yellow
Write-Host "   Just 'git push' to deploy automatically!" -ForegroundColor White
Write-Host ""
Write-Host "App ID (save this): $APP_ID" -ForegroundColor Yellow
Write-Host ""

# Save app ID to file
$APP_ID | Out-File -FilePath ".amplify-app-id" -NoNewline
Write-Host "App ID saved to .amplify-app-id file" -ForegroundColor Gray
