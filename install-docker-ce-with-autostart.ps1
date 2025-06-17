$ErrorActionPreference = "Stop"

# Set up logging
$log = "C:\docker-install-log.txt"
$start = Get-Date
Add-Content $log "`n==== Docker Install Script Started at: $start ===="

# Set Administrator password and enable RDP
Add-Content $log "Setting Administrator password and enabling RDP firewall rules..."
net user Administrator "YourStrongP@ssw0rd"
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
Add-Content $log "Admin setup complete."

# Define paths
$scriptFullPath = $MyInvocation.MyCommand.Definition
$dockerVersion = "28.2.2"
$dockerZipUrl = "https://download.docker.com/win/static/stable/x86_64/docker-$dockerVersion.zip"
$downloadPath = "$env:USERPROFILE\DockerDownloads"
$zipFile = "$downloadPath\docker-$dockerVersion.zip"
$extractPath = "$downloadPath\docker-$dockerVersion"
$system32 = "$env:windir\System32"

# Check and install Containers feature
Add-Content $log "Checking Containers feature..."
$feature = Get-WindowsFeature -Name Containers
if (-not $feature.Installed) {
    Add-Content $log "Containers feature not installed. Installing and setting RunOnce for resume..."

    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" `
        -Name "ResumeDockerInstall" `
        -Value "powershell -ExecutionPolicy Bypass -File `"$scriptFullPath`""

    Install-WindowsFeature -Name Containers -IncludeAllSubFeature -IncludeManagementTools
    Add-Content $log "System rebooting..."
    Restart-Computer -Force
    return
} else {
    Add-Content $log "Containers feature already installed."
}

# Download and extract Docker
New-Item -ItemType Directory -Force -Path $downloadPath | Out-Null

if (-Not (Test-Path $zipFile)) {
    Add-Content $log "Downloading Docker from $dockerZipUrl"
    Invoke-WebRequest -Uri $dockerZipUrl -OutFile $zipFile
} else {
    Add-Content $log "Docker zip already downloaded. Skipping download."
}

Add-Content $log "Extracting Docker zip..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-Not (Test-Path $extractPath)) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $extractPath)
} else {
    Add-Content $log "Extraction folder already exists. Skipping extraction."
}

# Copy binaries to System32
$binaries = @("docker.exe", "dockerd.exe")
foreach ($binary in $binaries) {
    $found = Get-ChildItem -Path $extractPath -Recurse -Filter $binary -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        Copy-Item -Path $found.FullName -Destination "$system32\$binary" -Force
        Add-Content $log "$binary copied to System32"
    } else {
        Add-Content $log "WARNING: $binary not found in extracted content"
    }
}

# Ensure System32 is in PATH
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $system32 })) {
    Add-Content $log "Adding System32 to PATH..."
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$system32", [EnvironmentVariableTarget]::Machine)
} else {
    Add-Content $log "System32 already in PATH"
}

# Register scheduled task to start dockerd
$taskName = "StartDockerDaemon"
$dockerdPath = "$system32\\dockerd.exe"

Add-Content $log "Registering Scheduled Task for dockerd..."
$action = New-ScheduledTaskAction -Execute $dockerdPath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    Add-Content $log "Scheduled Task '$taskName' created successfully."
} catch {
    Add-Content $log "WARNING: Could not create Scheduled Task: $_"
}

# Start Docker now
try {
    Add-Content $log "Starting Docker daemon manually..."
    Start-Process -FilePath $dockerdPath -WindowStyle Hidden
    Start-Sleep -Seconds 10
    docker info | Out-File -Append -FilePath $log
    Add-Content $log "Docker daemon started and verified."
} catch {
    Add-Content $log "ERROR: Failed to start Docker daemon: $_"
}

# Final logging
$end = Get-Date
$duration = $end - $start
Add-Content $log "==== Docker Install Script Ended at: $end ===="
Add-Content $log "==== Total Duration: $duration ===="
