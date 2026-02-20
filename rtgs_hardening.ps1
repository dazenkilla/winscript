# --- BAGIAN 1: KONFIGURASI PASSWORD & AUDIT ---

# Tentukan path untuk file konfigurasi sementara
$configFile = "$env:TEMP\fix_security_bank_std.inf"
$dbFile = "$env:TEMP\security_db.sdb"

# Isi konfigurasi disesuaikan SAMA PERSIS dengan temuan audit
$infContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1

[System Access]
; Enforce password history = 5 passwords remembered
PasswordHistorySize = 5
; Maximum password age = 90 days
MaximumPasswordAge = 90
; Minimum password age (1 hari agar tidak di-bypass)
MinimumPasswordAge = 1
; Minimum password length = 8 characters
MinimumPasswordLength = 8
; Password must meet complexity requirements = Enabled
PasswordComplexity = 1
; Store passwords using reversible encryption (Disabled)
ClearTextPassword = 0

[Event Audit]
; 3 = Success and Failure (Mencatat berhasil & gagal)
; Audit system events
AuditSystemEvents = 3
; Audit logon events
AuditLogonEvents = 3
; Audit account logon events
AuditAccountLogon = 3
"@

# Tulis konfigurasi ke file .inf
Set-Content -Path $configFile -Value $infContent -Encoding Unicode
Write-Host "[1/2] Menerapkan Kebijakan Password & Audit..."

# Jalankan secedit
secedit /configure /db $dbFile /cfg $configFile /areas SECURITYPOLICY

# Hapus file sementara
Remove-Item $configFile -Force
Remove-Item $dbFile -Force

# --- BAGIAN 2: SINKRONISASI WAKTU ---

Write-Host "`n[2/2] Mengatur Sinkronisasi Waktu (NTP Indonesia Pool)..."

# NTP VM 10.21.16.124 (PRD)
$NTPServers = "10.21.16.124"

# Stop service waktu sebentar
Stop-Service w32time

# Set NTP server list dan set ke manual sync
w32tm /config /syncfromflags:manual /manualpeerlist:"$NTPServers" /reliable:YES

# Start service lagi
Start-Service w32time

# Paksa update waktu sekarang juga
w32tm /config /update
w32tm /resync

Write-Host "Sukses sinkronisasi ke $NTPServers"
