$ErrorActionPreference = "Stop"

# Set Admin Password & Enable RDP
net user Administrator "YourStrongP@ssw0rd"
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes

# Check if Containers feature is enabled
$scriptFullPath = $MyInvocation.MyCommand.Definition
$dockerVersion = "28.2.2"
$dockerZipUrl = "https://download.docker.com/win/static/stable/x86_64/docker-$dockerVersion.zip"
$downloadPath = "$env:USERPROFILE\DockerDownloads"
$zipFile = "$downloadPath\docker-$dockerVersion.zip"
$extractPath = "$downloadPath\docker-$dockerVersion"
$system32 = "$env:windir\System32"

Write-Host "Checking Containers feature..."
$feature = Get-WindowsFeature -Name Containers
if (-not $feature.Installed) {
    Write-Host "Installing Containers feature. Reboot required..."

    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" `
        -Name "ResumeDockerInstall" `
        -Value "powershell -ExecutionPolicy Bypass -File `"$scriptFullPath`""

    Install-WindowsFeature -Name Containers -IncludeAllSubFeature -IncludeManagementTools
    Restart-Computer -Force
    return
}

# Download and Extract Docker
New-Item -ItemType Directory -Force -Path $downloadPath | Out-Null

if (-Not (Test-Path $zipFile)) {
    Invoke-WebRequest -Uri $dockerZipUrl -OutFile $zipFile
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-Not (Test-Path $extractPath)) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $extractPath)
}

# Copy docker binaries
$binaries = @("docker.exe", "dockerd.exe")
foreach ($binary in $binaries) {
    $found = Get-ChildItem -Path $extractPath -Recurse -Filter $binary -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        Copy-Item -Path $found.FullName -Destination "$system32\$binary" -Force
    }
}

# Ensure System32 is in PATH
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $system32 })) {
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$system32", [EnvironmentVariableTarget]::Machine)
}

# Register Scheduled Task for dockerd
$taskName = "StartDockerDaemon"
$dockerdPath = "$system32\\dockerd.exe"

$action = New-ScheduledTaskAction -Execute $dockerdPath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
} catch {
    Write-Host "Scheduled task may already exist or failed to create: $_"
}

# Start Docker now (non-blocking)
try {
    Start-Process -FilePath $dockerdPath -WindowStyle Hidden
    Start-Sleep -Seconds 10
    docker info | Out-Host
} catch {
    Write-Host "Docker failed to start immediately. May work after reboot."
}
