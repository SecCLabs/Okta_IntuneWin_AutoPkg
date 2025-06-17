# Script to deploy Okta Verify to Intune

# Variables
$sourcePath = "C:\IntunePackaging\OktaVerify\Source\"
$outputPath = "C:\IntunePackaging\OktaVerify\Output\"
$intuneWinAppUtilPath = "C:\IntuneTools\IntuneWinAppUtil\"
$oktaVerifyInstaller = "OktaVerify_Install.exe"
$envFilePath = "$intuneWinAppUtilPath.env"

# Create directories
Write-Host "Creating required directories..." -ForegroundColor Cyan
try {
    New-Item -ItemType Directory -Force -Path $sourcePath | Out-Null
    New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
    New-Item -ItemType Directory -Force -Path $intuneWinAppUtilPath | Out-Null
    Write-Host "✓ Directories created successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Error creating directories: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create .env file if it doesn't exist
if (-not (Test-Path $envFilePath)) {
    Write-Host "Creating .env configuration file..." -ForegroundColor Cyan
    $envContent = @"
# Intune Win32 App Deployment Configuration
# Add your Okta Verify .exe file download URL below:
OKTA_VERIFY_URL=
"@
    Set-Content -Path $envFilePath -Value $envContent
    Write-Host "✓ .env file created at: $envFilePath" -ForegroundColor Green
}

# Function to read .env file and set environment variables
function Load-EnvFile {
    param($FilePath)
    if (Test-Path $FilePath) {
        Get-Content $FilePath | ForEach-Object {
            if ($_ -match '^([^#=]+)=(.*)$') {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            }
        }
    }
}

# Load environment variables from .env file
Load-EnvFile -FilePath $envFilePath

# Check if Okta Verify URL is configured, if not prompt user
if (-not $ENV:OKTA_VERIFY_URL) {
    Write-Host "`nOkta Verify .exe download URL not configured." -ForegroundColor Yellow
    Write-Host "Grab your URL from: Okta Admin Console > Settings > Downloads > Okta Verify for Windows (.exe)" -ForegroundColor Cyan
    $oktaUrl = Read-Host "Please enter the Okta Verify .exe file download URL"
    
    if ($oktaUrl) {
        # Update the .env file with quoted URL
        $envContent = Get-Content $envFilePath
        $updatedContent = $envContent -replace "OKTA_VERIFY_URL=.*", "OKTA_VERIFY_URL=`"$oktaUrl`""
        Set-Content -Path $envFilePath -Value $updatedContent
        
        # Set the environment variable for current session
        [Environment]::SetEnvironmentVariable("OKTA_VERIFY_URL", $oktaUrl, "Process")
        Write-Host "✓ Okta Verify .exe URL saved and loaded" -ForegroundColor Green
    } else {
        Write-Host "✗ No URL provided. Cannot continue." -ForegroundColor Red
        exit 1
    }
}

# Download Okta Verify
Write-Host "Downloading Okta Verify installer..." -ForegroundColor Cyan
$oktaVerifyUrl = $ENV:OKTA_VERIFY_URL
$oktaVerifyExePath = "$sourcePath$oktaVerifyInstaller"
try {
    Invoke-WebRequest -Uri $oktaVerifyUrl -OutFile $oktaVerifyExePath
    Write-Host "✓ Okta Verify installer downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Error downloading Okta Verify: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check the OKTA_VERIFY_URL in your .env file" -ForegroundColor Yellow
    exit 1
}

# Setup IntuneWinAppUtil
Write-Host "Setting up Microsoft Win32 IntuneWin App Util..." -ForegroundColor Cyan
$intuneWinAppUtilUrl = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/heads/master.zip"
$intuneWinAppUtilZip = "IntuneWinAppUtil.zip"
$intuneWinAppUtilZipPath = "$intuneWinAppUtilPath$intuneWinAppUtilZip"

try {
    # Download, extract, and locate IntuneWinAppUtil
    Invoke-WebRequest -Uri $intuneWinAppUtilUrl -OutFile $intuneWinAppUtilZipPath
    Expand-Archive -Path $intuneWinAppUtilZipPath -DestinationPath "$intuneWinAppUtilPath" -Force
    Remove-Item $intuneWinAppUtilZipPath
    
    $intuneWinExePath = Get-ChildItem -Path $intuneWinAppUtilPath -Recurse -Name "IntuneWinAppUtil.exe" | Select-Object -First 1
    if (-not $intuneWinExePath) {
        throw "IntuneWinAppUtil.exe not found after extraction"
    }
    $fullIntuneWinExePath = Join-Path $intuneWinAppUtilPath $intuneWinExePath
    Write-Host "✓ IntuneWinAppUtil setup complete" -ForegroundColor Green
} catch {
    Write-Host "✗ Error setting up IntuneWinAppUtil: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Run the packaging command
Write-Host "Creating .intunewin package..." -ForegroundColor Cyan
try {
    & $fullIntuneWinExePath -c $sourcePath -s $oktaVerifyInstaller -o $outputPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Package created successfully!" -ForegroundColor Green
        Write-Host "Output location: $outputPath" -ForegroundColor Cyan
        
        # Clean up temporary files
        Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
        Remove-Item "$sourcePath$oktaVerifyInstaller" -ErrorAction SilentlyContinue
        Remove-Item $envFilePath -ErrorAction SilentlyContinue
        Write-Host "✓ Cleanup complete" -ForegroundColor Green
    } else {
        Write-Host "✗ IntuneWinAppUtil failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error running IntuneWinAppUtil: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure the Okta Verify installer was downloaded correctly" -ForegroundColor Yellow
    exit 1
}
