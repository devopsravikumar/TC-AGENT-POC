# install-docker-ce.ps1
# Script to install Docker CE on Windows Server

# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Error "You must run this script as Administrator!"
    exit 1
}

Write-Host "`n=== Installing Docker on Windows Server ===`n"

# Set TLS12 as security protocol (fix for older systems)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install DockerMsftProvider if not present
if (-not (Get-Module -ListAvailable -Name DockerMsftProvider)) {
    Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
}

# Install Docker (ignore warning if already installed)
if (-not (Get-Package -Name docker -ErrorAction SilentlyContinue)) {
    Install-Package -Name docker -ProviderName DockerMsftProvider -Force
} else {
    Write-Host "Docker is already installed. Skipping install."
}

# Start/Restart Docker service
Write-Host "`nRestarting Docker service..."
Restart-Service docker

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
docker version

Write-Host "`n=== Docker installation complete! ===`n"
