# Set execution policy
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Bypass -Force
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force

# Install necessary modules
$modules = @("AuditPolicyDsc", "SecurityPolicyDsc", "PSDesiredStateConfiguration", "DellBIOSProvider")
foreach ($module in $modules) {
    Install-Module -Name $module -Force -Verbose
}

# Set network profile to Private
$profile = Get-NetConnectionProfile
if ($profile) {
    Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private
}

# 1. Set Time Zone secara manual ke Jakarta (GMT +7)
Set-TimeZone -Id "SE Asia Standard Time"

# 2. Disable Time Zone Auto Update (Mencegah perubahan otomatis)
$TZAutoSettingRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate"
Set-ItemProperty -Path $TZAutoSettingRegPath -Name "Start" -Value 3
