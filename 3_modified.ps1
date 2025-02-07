# Create installer directory
New-Item -Path 'C:\installer' -ItemType Directory -Force

# Download necessary files
$downloads = @{
    "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/standardapps.zip" = "C:/installer/standardapps.zip"
    "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/winscript/ZoomMeetingsGlobalPolicySuperbank.reg" = "C:/installer/ZoomMeetingsGlobalPolicySuperbank.reg"
    "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64" = "C:/installer/zoom.msi"
    "https://github.com/pritunl/pritunl-client-electron/releases/download/1.3.3709.64/Pritunl.exe" = "C:/installer/pritunl.exe"
    "https://www.7-zip.org/a/7z2301-x64.msi" = "C:/installer/7zip.msi"
    "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" = "C:/installer/chrome.msi"
    "https://slack.com/ssb/download-win64-msi" = "C:/installer/slack.msi"
}
Start-Sleep 10
foreach ($url in $downloads.Keys) {
    Invoke-WebRequest -Uri $url -OutFile $downloads[$url]
}

# Extract standard apps archive
Expand-Archive -Path "C:/installer/standardapps.zip" -DestinationPath "C:/installer"
cd C:\installer
# Install MSI packages
$msiFiles = @{
    "7zip.msi" = '/I 7zip.msi /quiet'
    "chrome.msi" = '/I chrome.msi /quiet'
    "slack.msi" = '/I slack.msi INSTALLLEVEL=2 /quiet'
    "zoom.msi" = '/I zoom.msi zConfig="RemoteControlAllApp=1;nogoogle=1;nofacebook=1;EnableAppleLogin=0" /norestart /quiet'
}
Start-Sleep 15
Set-Location -Path 'C:\installer\'
foreach ($msi in $msiFiles.Keys) {
    Start-Process msiexec.exe -Wait -ArgumentList $msiFiles[$msi]
}

# Move user.bat to startup folder
Move-Item -Path "C:\installer\user.bat" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"

# Import Zoom global policy registry
reg import "C:/installer/ZoomMeetingsGlobalPolicySuperbank.reg"

# Install Pritunl client
Start-Process -FilePath "C:\installer\pritunl.exe" -Verb runAs -ArgumentList '/R /VERYSILENT'
Start-Sleep 10
# Install Cisco Secure Endpoint
Start-Process -FilePath "C:\installer\amp_protect.exe" -Verb runAs -ArgumentList '/R /S'
Start-Sleep 10

# Install Qualys Cloud Agent
(New-Object System.Net.WebClient).DownloadFile("https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/QualysCloudAgent.exe", "$env:TEMP/QualysCloudAgent.exe")
$arguments = "CustomerId={5e178b8d-acec-d296-8055-4a60ceddc5fd} ActivationId={dc068396-6b29-4876-9ac3-9130be06350f} WebServiceUri=https://qagpublic.qg1.apps.qualys.in/CloudAgent/"
function InstallQualysAgent {
Start-Process -FilePath "$env:TEMP\qualysCloudAgent.exe" $arguments
}
InstallQualysAgent
Start-Sleep 10

# Install JumpCloud agent
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/TheJumpCloud/support/master/scripts/windows/InstallWindowsAgent.ps1" -OutFile "$env:temp\InstallWindowsAgent.ps1"
& "$env:temp\InstallWindowsAgent.ps1" -JumpCloudConnectKey "5ede3dd0e94e49f715ca4ba4074b2849f95edf1c"
Start-Sleep 15
# Prompt for completion
Read-Host -Prompt "Apps Installed! Press any key to continue"

# Install dotnet core runtime 8.0.11
# Variables
$installerUrl = "https://download.visualstudio.microsoft.com/download/pr/53e9e41c-b362-4598-9985-45f989518016/53c5e1919ba2fe23273f2abaff65595b/dotnet-runtime-8.0.11-win-x64.exe"
$localPath = "C:\temp\dotnet-runtime-8.0.11-win-x64.exe"
$requiredRuntimeVersion = "8.0.11"

# Function to Check Installed Runtimes
function Check-DotNetRuntime {
    $runtimes = &dotnet --list-runtimes 2>$null
    return $runtimes -match "Microsoft\.AspNetCore\.App\s+$requiredRuntimeVersion" -or 
           $runtimes -match "Microsoft\.NETCore\.App\s+$requiredRuntimeVersion"
}

# Check if .NET Runtime 8.0.11 is installed
if (Check-DotNetRuntime) {
    Write-Output "Already installed"
} else {
    # Ensure the directory exists
    if (-not (Test-Path -Path (Split-Path $localPath))) {
        New-Item -ItemType Directory -Path (Split-Path $localPath) -Force
    }

    # Download the installer
    Invoke-WebRequest -Uri $installerUrl -OutFile $localPath

    # Run the installer silently
    Start-Process -FilePath $localPath -ArgumentList "/quiet", "/norestart" -Wait

    # Verify installation
    if (Check-DotNetRuntime) {
        Write-Output "Installed .NET Runtime 8.0.11"
    } else {
        Write-Output "Installation failed. Please check the logs."
    }
}

# Remove other dotnet version except 8.0.11
# Variables
$msiUrl = "https://github.com/dotnet/cli-lab/releases/download/1.7.550802/dotnet-core-uninstall-1.7.550802.msi"
$localMsiPath = "C:\temp\dotnet-core-uninstall.msi"
$uninstallToolPath = "C:\Program Files (x86)\dotnet-core-uninstall\dotnet-core-uninstall.exe"
$requiredVersion = "8.0.11"
$foldersToClean = @(
    "C:\Program Files\dotnet\shared\Microsoft.NETCore.App",
    "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App"
)

# Function to Compare Versions
function Compare-Version {
    param (
        [string]$versionA,
        [string]$versionB
    )
    return ([version]$versionA -ge [version]$versionB)  # True if versionA is >= versionB
}

# Function to Check if .NET Runtime 8.0.11 or above is Installed
function Check-DotNetRuntime {
    $runtimes = &dotnet --list-runtimes 2>$null
    $installedVersions = $runtimes | Select-String -Pattern "Microsoft\.(AspNetCore|NETCore)\.App\s+(\d+\.\d+\.\d+)" | ForEach-Object {
        $_ -match "(\d+\.\d+\.\d+)"
        $matches[1]
    }

    # Check if at least one installed version is >= 8.0.11
    foreach ($version in $installedVersions) {
        if (Compare-Version -versionA $version -versionB $requiredVersion) {
            return $true
        }
    }
    return $false
}

# Step 1: Check if .NET Runtime 8.0.11 or above is Installed
if (Check-DotNetRuntime) {
    Write-Output ".NET Runtime $requiredVersion or above is installed. Proceeding with cleanup..."
    
    # Step 2: Install the .NET Core Uninstall Tool if Not Already Installed
    if (-not (Test-Path $uninstallToolPath)) {
        if (-not (Test-Path -Path (Split-Path $localMsiPath))) {
            New-Item -ItemType Directory -Path (Split-Path $localMsiPath) -Force
        }
        Invoke-WebRequest -Uri $msiUrl -OutFile $localMsiPath
        Start-Process msiexec.exe -ArgumentList "/i", $localMsiPath, "/quiet", "/norestart" -Wait
    }

    # Step 3: Use Uninstall Tool to Remove Older Versions Only
    $installedRuntimes = & $uninstallToolPath list --runtime
    $runtimesToRemove = $installedRuntimes | Select-String -Pattern "\d+\.\d+\.\d+" | ForEach-Object {
        $_ -match "(\d+\.\d+\.\d+)"
        $version = $matches[1]
        if (-not (Compare-Version -versionA $version -versionB $requiredVersion)) {
            $version  # Remove only if it's older than 8.0.11
        }
    }
    foreach ($version in $runtimesToRemove) {
        & $uninstallToolPath remove --runtime $version --yes
    }

    # Step 4: Force Remove Leftover Directories
    function Remove-With-Ownership {
        param (
            [string]$path
        )
        # Take ownership of the folder
        takeown.exe /F $path /A /R /D Y
        # Grant full control to Administrators
        icacls.exe $path /grant Administrators:F /T
        # Remove the folder
        Remove-Item -Recurse -Force $path
        Write-Output "Forcefully deleted folder: $path"
    }
    foreach ($folder in $foldersToClean) {
        if (Test-Path $folder) {
            Get-ChildItem -Path $folder -Directory | Where-Object { -not (Compare-Version -versionA $_.Name -versionB $requiredVersion) } | ForEach-Object {
                Remove-With-Ownership -path $_.FullName
            }
        } else {
            Write-Output "Folder not found: $folder"
        }
    }

    Write-Output "Removed runtimes: $runtimesToRemove"
} else {
    Write-Output ".NET Runtime $requiredVersion or above is NOT installed. Skipping deletion process."
}

# Disable IPv6
# Get all network adapters
$adapters = Get-NetAdapter

foreach ($adapter in $adapters) {
    # Disable IPv6 on each adapter
    Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6
}

# Remove the installer directory
Remove-Item -Path "C:\installer" -Recurse -Force

# Clean up Downloads folder
$downloadsPath = "~\Downloads\"
Get-ChildItem $downloadsPath | Remove-Item -Recurse -Force
