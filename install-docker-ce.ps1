# install-docker-ce.ps1
# Fully non-interactive Docker install for Windows Server via WinRM/CI

$ProgressPreference      = 'SilentlyContinue'
$ConfirmPreference       = 'None'
$ErrorActionPreference   = 'Stop'

Write-Host "`n=== Installing Docker on Windows Server ===`n"

# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Error "You must run this script as Administrator!"
    exit 1
}

# Set TLS12 as security protocol (for PowerShell Gallery access)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# PREVENT ShouldContinue for NuGet/Provider
Write-Host "Ensuring NuGet provider is installed (non-interactive)..."
$provider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $provider) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
}
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install DockerMsftProvider if not present
if (-not (Get-Module -ListAvailable -Name DockerMsftProvider)) {
    Write-Host "Installing DockerMsftProvider..."
    Install-Module -Name DockerMsftProvider -Repository PSGallery -Force -Confirm:$false
} else {
    Write-Host "DockerMsftProvider is already installed."
}

# Install Docker if not already present
if (-not (Get-Package -Name docker -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Docker..."
    Install-Package -Name docker -ProviderName DockerMsftProvider -Force -ForceBootstrap -Confirm:$false
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
try {
    docker version
} catch {
    Write-Warning "Docker is installed, but could not run 'docker version'. You may need to log off and back in for group membership to take effect."
}

Write-Host "`n=== Docker installation complete! ===`n"
