$ErrorActionPreference = "Stop"
$scriptFullPath = $MyInvocation.MyCommand.Definition
$dockerVersion = "28.2.2"
$dockerZipUrl = "https://download.docker.com/win/static/stable/x86_64/docker-$dockerVersion.zip"
$downloadPath = "$env:USERPROFILE\DockerDownloads"
$zipFile = "$downloadPath\docker-$dockerVersion.zip"
$extractPath = "$downloadPath\docker-$dockerVersion"
$system32 = "$env:windir\System32"

# -------------------------------
# 1. Enable Containers Feature
# -------------------------------
Write-Host ""
Write-Host "Checking Windows 'Containers' feature..."
$feature = Get-WindowsFeature -Name Containers
if (-not $feature.Installed) {
    Write-Host "Installing 'Containers' feature. Reboot required..."

    # Register this script to run once after reboot
    Write-Host "Registering script to resume after reboot using RunOnce..."
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" `
        -Name "ResumeDockerInstall" `
        -Value "powershell -ExecutionPolicy Bypass -File `"$scriptFullPath`""

    Install-WindowsFeature -Name Containers -IncludeAllSubFeature -IncludeManagementTools
    Restart-Computer -Force
    return
} else {
    Write-Host "'Containers' feature already installed."
}

# -------------------------------
# 2. Download and Extract Docker
# -------------------------------
Write-Host ""
Write-Host "Creating Docker download folder..."
New-Item -ItemType Directory -Force -Path $downloadPath | Out-Null

if (-Not (Test-Path $zipFile)) {
    Write-Host "Downloading Docker $dockerVersion..."
    Invoke-WebRequest -Uri $dockerZipUrl -OutFile $zipFile
} else {
    Write-Host "Docker ZIP already exists. Skipping download."
}

Write-Host "Extracting ZIP to $extractPath..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-Not (Test-Path $extractPath)) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $extractPath)
} else {
    Write-Host "Extraction folder already exists. Skipping extraction."
}

# -------------------------------
# 3. Copy Docker Binaries to System32
# -------------------------------
Write-Host ""
$binaries = @("docker.exe", "dockerd.exe")
foreach ($binary in $binaries) {
    $found = Get-ChildItem -Path $extractPath -Recurse -Filter $binary -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        Write-Host "Copying $binary to $system32"
        Copy-Item -Path $found.FullName -Destination "$system32\$binary" -Force
    } else {
        Write-Host "WARNING: $binary not found in extracted ZIP."
    }
}

# -------------------------------
# 4. Ensure System32 in PATH
# -------------------------------
Write-Host ""
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $system32 })) {
    Write-Host "Adding System32 to PATH..."
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$system32", [EnvironmentVariableTarget]::Machine)
} else {
    Write-Host "System32 is already in PATH."
}

# -------------------------------
# 5. Create Scheduled Task for dockerd
# -------------------------------
Write-Host ""
$taskName = "StartDockerDaemon"
$dockerdPath = "$system32\dockerd.exe"

if (-Not (Test-Path $dockerdPath)) {
    Write-Host "ERROR: dockerd.exe not found. Cannot create Scheduled Task."
    exit 1
}

Write-Host "Registering Scheduled Task '$taskName' to run dockerd.exe at startup..."
$action = New-ScheduledTaskAction -Execute $dockerdPath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    Write-Host "Scheduled Task created successfully."
} catch {
    Write-Host "WARNING: Could not create Scheduled Task. It may already exist."
}

# -------------------------------
# 6. Start Docker Daemon Immediately
# -------------------------------
Write-Host ""
Write-Host "Attempting to start Docker daemon now..."
try {
    Start-Process -FilePath $dockerdPath -WindowStyle Hidden
    Start-Sleep -Seconds 10
    docker info | Out-Host
    Write-Host "Docker is up and running."
} catch {
    Write-Host "WARNING: Could not start Docker daemon manually. Reboot may be required."
}
