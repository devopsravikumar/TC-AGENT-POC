$marker = "C:\docker_install_marker.txt"
$gcsScriptUrl = "https://storage.googleapis.com/tc-agent-poc/scripts_install-docker-ce.ps1"
$localInstaller = "C:\scripts_install-docker-ce.ps1"
$logFile = "C:\docker_install_log.txt"
$errorLog = "C:\docker_install_error.log"

if (-Not (Test-Path $marker)) {
    try {
        "Downloading script from $gcsScriptUrl..." | Out-File $logFile -Append

        Invoke-WebRequest -Uri $gcsScriptUrl -OutFile $localInstaller -UseBasicParsing

        if (-Not (Test-Path $localInstaller)) {
            throw "Failed to download $gcsScriptUrl"
        }

        Unblock-File -Path $localInstaller

        "Executing downloaded Docker install script..." | Out-File $logFile -Append
        & powershell.exe -ExecutionPolicy Bypass -File $localInstaller -ErrorAction Stop

        # Validate Docker is installed
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw "Docker command not found after install"
        }

        "Docker installed successfully. Creating marker and rebooting..." | Out-File $logFile -Append
        New-Item -Path $marker -ItemType File -Force

        Restart-Computer -Force
    }
    catch {
        "ERROR: $($_.Exception.Message)" | Out-File $errorLog -Append
    }
}
else {
    "Startup skipped — docker_install_marker exists" | Out-File $logFile -Append
}
