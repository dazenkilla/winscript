#====================================================================================#
# SETTING UP BIOS ADMIN PASSWORD
#====================================================================================#
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Bypass -Force
#Set BIOS Password
# Check if DellBIOSProvider module is installed
$moduleName = "DellBIOSProvider"
$biosPasswordPath = "DellSmbios:\Security\AdminPassword"
$lockoutPath = "DellSmbios:\Security\AdminSetupLockout"
$strongPasswordPath = "DellSmbios:\Security\StrongPassword"
$adminPassword = "R1d3r5m4n?"
$lockout = "Enabled"
$strong = "Enabled"

# Function to install DellBIOSProvider module if not present
function Install-DellBIOSProvider {
    Write-Host "DellBIOSProvider module not found. Installing..."
    Install-Module -Name $moduleName -Force -SkipPublisherCheck
}

# Check if module is installed, install if not
if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Install-DellBIOSProvider
}

# Import the module
Import-Module -Name $moduleName -Force

# Check if the BIOS AdminPassword is already set
$biosPasswordSet = (Get-Item -Path $biosPasswordPath).CurrentValue
if (-not $biosPasswordSet) {
    # Set the BIOS AdminPassword if not set
    Set-Item -Path $biosPasswordPath -Value $adminPassword
	Set-Item -Path $lockoutPath -Value $lockout
	Set-Item -Path $strongPasswordPath -Value $strong
    Write-Host "BIOS AdminPassword has been set."
} else {
    Write-Host "BIOS AdminPassword is already set."
}

 
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
# FORCEPOINT INSTALLER
#====================================================================================#
Write-Output "WAITING IF ANY DELAYED PROCESS"
Start-Sleep 5

# Daftar file yang akan diunduh
$urls = @(
    @{url = "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/Bitglass-SmartEdge-Autoinstaller-x64-1.3.4.msi"; dest = "C:/Windows/TEMP/Bitglass-SmartEdge-Autoinstaller-x64-1.3.4.msi"},
    @{url = "https://idbank-cen-corp-it-files.s3.ap-southeast-3.amazonaws.com/wininstaller/autoinstall.bat"; dest = "C:/Windows/TEMP/autoinstall.bat"}
)

# Download file
foreach ($item in $urls) {
    Write-Output "DOWNLOADING: $($item.url)"
    Invoke-WebRequest -Uri $item.url -OutFile $item.dest
}

# Jalankan file BAT untuk install Forcepoint
Write-Output "INSTALLING FORCEPOINT..."
Start-Process -FilePath "C:/Windows/TEMP/autoinstall.bat" -Verb runAs
Start-Sleep -Seconds 5

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

