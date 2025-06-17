# Okta Verify Intune Win32 App Deployment Script

This PowerShell script automates the process of packaging Okta Verify for deployment through Microsoft Intune as a Win32 app.

## What This Script Does

1. **Downloads Okta Verify** - Fetches the Windows .exe installer from your Okta organization
2. **Downloads Microsoft Win32 Content Prep Tool** - Gets the latest IntuneWinAppUtil from GitHub
3. **Creates .intunewin Package** - Packages Okta Verify into the format required by Intune
4. **Manages Configuration** - Handles URL storage and retrieval automatically
5. **Cleans Up** - Automatically removes temporary files after successful packaging

## Requirements

### PowerShell Execution Policy
An execution policy of at least **RemoteSigned** is required. For security, it's recommended to scope this to the current process only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

### Administrator Rights
The script should be run from a PowerShell instance with Administrator privileges to ensure proper directory creation and file downloads.

### Internet Connection
Required for downloading:
- Microsoft Win32 Content Prep Tool from GitHub
- Okta Verify installer from your Okta organization

## Usage

### First Run
1. Set the execution policy: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`
2. Run the script as Administrator
3. When prompted, enter your Okta Verify .exe download URL
   - Find this in: **Okta Admin Console > Settings > Downloads > Okta Verify for Windows (.exe)**
4. The script will automatically download, package, create the .intunewin file, and clean up temporary files

### Subsequent Runs
You'll need to enter your Okta Verify URL each time, as the configuration file is cleaned up after each successful run for security.

## Output

The script creates the following directory structure:

```
C:\IntunePackaging\OktaVerify\
├── Source\                    # Temporary - cleaned up after packaging
└── Output\                    # Contains the final .intunewin package

C:\IntuneTools\IntuneWinAppUtil\
└── Microsoft-Win32-Content... # Extracted packaging tool
```

**Note:** After successful packaging, the script automatically removes:
- The downloaded Okta Verify installer from the Source folder
- The temporary .env configuration file

## Configuration

The script temporarily creates a `.env` configuration file during execution but removes it after successful packaging for security purposes. You'll be prompted for your Okta Verify URL each time you run the script.

## Troubleshooting

### Common Issues

**"Execution of scripts is disabled"**
- Run the execution policy command mentioned in Requirements

**"Access denied" errors**
- Ensure you're running PowerShell as Administrator

**"Cannot validate argument on parameter 'Uri'"**
- Check that your Okta Verify URL is valid and points to the .exe file

### Getting Your Okta Verify URL

1. Log into your Okta Admin Console
2. Navigate to **Settings > Downloads**
3. Find **Okta Verify for Windows**
4. Right-click the download button and copy the link address
5. Use this URL when prompted by the script

## Next Steps

After the script completes successfully:

1. Upload the `.intunewin` file from the Output folder to Intune
2. Configure your Win32 app settings in the Microsoft Endpoint Manager admin center
3. Assign the app to your desired groups

## Security Notes
- The script uses Process-scoped execution policy for security
- Downloads are performed over HTTPS
- Temporary files (installer and configuration) are automatically cleaned up after successful packaging
- No sensitive URLs are left as variables on the terminal after completion