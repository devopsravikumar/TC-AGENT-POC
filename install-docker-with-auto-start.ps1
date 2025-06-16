# Path to Docker daemon
$dockerdPath = "C:\Windows\System32\dockerd.exe"

# Check if Docker daemon exists
if (-Not (Test-Path $dockerdPath)) {
    Write-Output "dockerd.exe not found at $dockerdPath. Please ensure Docker is copied before running this script."
    Exit 1
}

# Define Scheduled Task
$taskName = "StartDockerDaemon"
$action = New-ScheduledTaskAction -Execute $dockerdPath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    # Register the task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    Write-Output "Scheduled task '$taskName' created successfully."
} catch {
    Write-Error "Failed to create scheduled task: $_"
    Exit 1
}

# Start Docker daemon immediately
try {
    Start-Process -FilePath $dockerdPath -WindowStyle Hidden
    Write-Output "Docker daemon started successfully."
} catch {
    Write-Error "Failed to start Docker daemon: $_"
    Exit 1
}
