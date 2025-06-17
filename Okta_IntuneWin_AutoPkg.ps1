# Script to deploy Okta Verify to Intune

# Variables
$sourcePath = "C:\IntunePackaging\OktaVerify\Source\"
$outputPath = "C:\IntunePackaging\OktaVerify\Output\"
$intuneWinAppUtilPath = "C:\IntuneTools\IntuneWinAppUtil\"
$oktaVerifyInstaller = "OktaVerify_Install.exe"

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

# Prompt for Okta Verify URL
Write-Host "`nOkta Verify .exe download URL required." -ForegroundColor Yellow
Write-Host "Grab your URL from: Okta Admin Console > Settings > Downloads > Okta Verify for Windows (.exe)" -ForegroundColor Cyan
$oktaVerifyUrl = Read-Host "Please enter the Okta Verify .exe file download URL"

if (-not $oktaVerifyUrl) {
    Write-Host "✗ No URL provided. Cannot continue." -ForegroundColor Red
    exit 1
}

# Download Okta Verify
Write-Host "Downloading Okta Verify installer..." -ForegroundColor Cyan
$oktaVerifyExePath = "$sourcePath$oktaVerifyInstaller"
try {
    Invoke-WebRequest -Uri $oktaVerifyUrl -OutFile $oktaVerifyExePath
    Write-Host "✓ Okta Verify installer downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Error downloading Okta Verify: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check the URL you provided" -ForegroundColor Yellow
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
        Write-Host "Output location: $outputPath" -ForegroundColor Magenta
    } else {
        Write-Host "✗ IntuneWinAppUtil failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error running IntuneWinAppUtil: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure the Okta Verify installer was downloaded correctly" -ForegroundColor Yellow
} finally {
    # Always clean up sensitive data and temporary files
    Write-Host "Cleaning up..." -ForegroundColor Cyan
    
    # Always clear sensitive variables from memory
    $oktaVerifyUrl = $null
    
    # Clean up downloaded installer (comment this out if you need to debug)
    Remove-Item "$sourcePath$oktaVerifyInstaller" -ErrorAction SilentlyContinue
    
    Write-Host "✓ Cleanup complete" -ForegroundColor Cyan
}
