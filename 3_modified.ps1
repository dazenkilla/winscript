# Create installer directory
New-Item -Path 'C:\installer' -ItemType Directory -Force

# Download necessary files
$downloads = @{
    "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/winscript/ZoomMeetingsGlobalPolicySuperbank.reg" = "C:/installer/ZoomMeetingsGlobalPolicySuperbank.reg"
    "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64" = "C:/installer/zoom.msi"
    "https://www.7-zip.org/a/7z2301-x64.msi" = "C:/installer/7zip.msi"
    "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" = "C:/installer/chrome.msi"
    "https://slack.com/ssb/download-win64-msi" = "C:/installer/slack.msi"
    "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/user.bat" = "C:/installer/user.bat"
    "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/run.ps1" = "C:/installer/run.ps1"
}
Start-Sleep 10
foreach ($url in $downloads.Keys) {
    # Invoke-WebRequest -Uri $url -OutFile $downloads[$url]
    curl.exe -L $url -o $downloads[$url]
}

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
Move-Item -Path "C:\installer\run.ps1" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"

# Import Zoom global policy registry
reg import "C:/installer/ZoomMeetingsGlobalPolicySuperbank.reg"

#====================================================================================#
# INSTALL CISCO SECURE ENDPOINT PROTECTION
#====================================================================================#
Write-Output "CISCO SECURE ENDPOINT PROTECTION"
# (New-Object System.Net.WebClient).DownloadFile("https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/amp_Protect.exe", "$env:TEMP/amp_Protect.exe")
curl.exe -L "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/amp_Protect.exe" -o "$env:TEMP/amp_Protect.exe"
function CiscoSecureEndpoint {
Start-Process -FilePath "$env:TEMP\amp_Protect.exe" -ArgumentList '/R /S'
}
CiscoSecureEndpoint
Start-Sleep 30

# Install Qualys Cloud Agent
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
curl.exe -L "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/QualysCloudAgent.exe" -o "$env:TEMP\QualysCloudAgent.exe"
$arguments = "CustomerId={5e178b8d-acec-d296-8055-4a60ceddc5fd} ActivationId={dc068396-6b29-4876-9ac3-9130be06350f} WebServiceUri=https://qagpublic.qg1.apps.qualys.in/CloudAgent/"

function InstallQualysAgent {
    Start-Process -FilePath "$env:TEMP\QualysCloudAgent.exe" -ArgumentList $arguments
}

InstallQualysAgent

# Install JumpCloud agent
# Invoke-RestMethod -Uri "https://raw.githubusercontent.com/TheJumpCloud/support/master/scripts/windows/InstallWindowsAgent.ps1" -OutFile "$env:temp\InstallWindowsAgent.ps1"
curl.exe -L "https://raw.githubusercontent.com/TheJumpCloud/support/master/scripts/windows/InstallWindowsAgent.ps1" -o "$env:temp\InstallWindowsAgent.ps1"
& "$env:temp\InstallWindowsAgent.ps1" -JumpCloudConnectKey "5ede3dd0e94e49f715ca4ba4074b2849f95edf1c"
Start-Sleep 15
# Prompt for completion
Read-Host -Prompt "Apps Installed! Press any key to continue"

#====================================================================================#
# INSTALL FORTICLIENT
#====================================================================================#

# # Bypass SSL validation
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
# [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# # Define variables
# $URL = "https://ztnavpn.cen.super-id.net:10443/installers/Default/collection-agent/msi/x64/FortiClient.msi"
# $Path = "C:\Windows\Temp\FortiClient.msi"

# # Download the file
# $webclient = New-Object System.Net.WebClient
# try {
#     $webclient.DownloadFile($URL, $Path)
#     Write-Host "Download successful: $Path"
# } catch {
#     Write-Host "Error downloading FortiClient: $_"
#     Read-Host "Press Enter to exit"
#     exit 1
# }

# # Install FortiClient silently
# if (Test-Path $Path) {
#     Write-Host "Starting FortiClient installation..."
#     Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$Path`" /quiet /norestart" -Verb RunAs -Wait
#     Write-Host "FortiClient installation completed."
# } else {
#     Write-Host "Installation file not found: $Path"
#     Read-Host "Press Enter to exit"
#     exit 1
# }


#====================================================================================#
# CHECKING APP INSTALLATION FOLDERS AND RELATED SERVICES BEFORE INSTALLING FORCEPOINT
#====================================================================================#
Write-Output "WAITING IF ANY DELAYED PROCESS"
Start-Sleep 30
$CiscoInstallPath = "C:\Program Files\Cisco\AMP"
$QualysInstallPath = "C:\Program Files\Qualys\QualysAgent"
$JumpcloudInstallPath = "C:\Program Files\JumpCloud"

# Function to check if their service is running
function Is-ServiceIsRunning {
	$isCiscoInstalled = Test-Path $CiscoInstallPath
	$isQualysInstalled = Test-Path $QualysInstallPath
	$isJumpcloudInstalled = Test-Path $JumpcloudInstallPath
    $isCiscoServiceRunning = Get-Service -Name "CiscoAMP" -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Running'}
    $isQualysServiceRunning = Get-Service -Name "QualysAgent" -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Running'}
    $isJumpcloudServiceRunning = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Running'}
    return $isCiscoInstalled -and $isQualysInstalled -and $isJumpcloudInstalled -and $isCiscoServiceRunning -and $isQualysServiceRunning -and $isJumpcloudServiceRunning
}

#====================================================================================#
# DOWNLOAD & INSTALL FORCEPOINT WHEN ALL APP NEEDED IS SUCCESSFULLY INSTALLED
#====================================================================================#
Write-Output "WAITING FOR DELAYED PROCESS"
Start-Sleep 30
if (Is-ServiceIsRunning){
	Write-Output "CISCO | QUALYS | JUMPCLOUD PERFECTLY INSTALLED AND RUNNING. PROCEEDING TO INSTALL FORCEPOINT"
	$urls = @(
		@{url = "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/Bitglass-SmartEdge-Autoinstaller-x64-1.3.3.msi"; dest = "C:/Windows/TEMP/Bitglass-SmartEdge-Autoinstaller-x64-1.3.3.msi"},
		@{url = "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/autoinstall.bat"; dest = "C:/Windows/TEMP/autoinstall.bat"}
	)

	# Download files
	foreach ($item in $urls) {
		Invoke-WebRequest -Uri $item.url -OutFile $item.dest
	}

	Start-Process -FilePath "C:/Windows/TEMP/autoinstall.bat" -Verb runAs
	Start-Sleep -Seconds 5
} else {
	Write-Output "ONE OR MORE APPLICATION ARE NOT PROPERLY INSTALLED. ABORTING INSTALL FORCEPOINT"
}

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
