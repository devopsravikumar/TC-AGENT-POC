# install-docker-ce.ps1
# Robust, non-interactive Docker install for Windows Server 2022 (manual method)

$ProgressPreference      = 'SilentlyContinue'
$ConfirmPreference       = 'None'
$ErrorActionPreference   = 'Stop'

Write-Host "`n=== Installing Docker on Windows Server 2022 ===`n"

# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Error "You must run this script as Administrator!"
    exit 1
}

# Set TLS12 as security protocol (for web requests)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download Docker 20.10 for Windows Server 2022
$dockerUrl = "https://download.docker.com/components/engine/windows-server/20.10/docker-20.10.24.zip"
$zipPath = "$env:TEMP\docker-20.10.24.zip"
$dockerPath = "C:\Program Files\Docker"

if (!(Test-Path $dockerPath)) {
    New-Item -ItemType Directory -Path $dockerPath | Out-Null
}

Write-Host "Downloading Docker..."
Invoke-WebRequest -Uri $dockerUrl -OutFile $zipPath

Write-Host "Extracting Docker..."
Expand-Archive -Path $zipPath -DestinationPath $dockerPath -Force

# Add Docker to the system PATH
if (($env:Path -split ';') -notcontains $dockerPath) {
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ";$dockerPath", [EnvironmentVariableTarget]::Machine)
}

# Install NSSM (to run dockerd as a service)
$nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
$nssmZip = "$env:TEMP\nssm.zip"
$nssmPath = "$env:TEMP\nssm"
$nssmExe = "$nssmPath\win64\nssm.exe"

if (!(Test-Path $nssmExe)) {
    Write-Host "Downloading NSSM..."
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip
    Expand-Archive -Path $nssmZip -DestinationPath $nssmPath -Force
}

# Install Docker as a Windows service using NSSM
Write-Host "Setting up Docker Engine service with NSSM..."
& $nssmExe install DockerEngine "$dockerPath\dockerd.exe"
& $nssmExe set DockerEngine Start SERVICE_AUTO_START

# Start the Docker service
Write-Host "Starting Docker service..."
Start-Service DockerEngine

# Add current user to docker-users group for non-admin Docker usage
$user = "$env:USERNAME"
if (-not (Get-LocalGroupMember -Group docker-users -Member $user -ErrorAction SilentlyContinue)) {
    Add-LocalGroupMember -Group "docker-users" -Member $user
    Write-Host "Added $user to docker-users group."
} else {
    Write-Host "$user is already a member of docker-users."
}

# Confirm installation
Write-Host "`nDocker version:"
try {
    docker version
} catch {
    Write-Warning "Docker is installed, but could not run 'docker version'. You may need to log off and back in for group membership to take effect."
}

Write-Host "`n=== Docker installation complete! ===`n"
