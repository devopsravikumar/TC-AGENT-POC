# Install gsutil if not already installed
if (!(Get-Command gsutil -ErrorAction SilentlyContinue)) {
    # Download and install gsutil (from Google Cloud SDK)
    Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -OutFile "$env:TEMP\GoogleCloudSDKInstaller.exe"
    Start-Process -Wait "$env:TEMP\GoogleCloudSDKInstaller.exe" -ArgumentList "/S"
    $env:Path += ";$Env:ProgramFiles\Google\Cloud SDK\google-cloud-sdk\bin"
}

# Download Docker Compose file from GCS
gsutil cp gs://tc-agent-poc/teamcity-compose.yml C:\teamcity-compose.yml

# Run Docker Compose
docker compose -f C:\teamcity-compose.yml up -d