# Install Docker
Invoke-WebRequest -UseBasicParsing -OutFile install-docker.ps1 `
  https://download.docker.com/win/static/stable/x86_64/docker-20.10.24.zip

Expand-Archive docker-20.10.24.zip -DestinationPath "C:\Docker"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Docker", [EnvironmentVariableTarget]::Machine)

Start-Process -FilePath "C:\Docker\dockerd.exe" -WindowStyle Hidden

# Enable firewall rules
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
