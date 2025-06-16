provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "win_vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = 100
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnet
    access_config {}
  }

  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }

  metadata = {
    windows-startup-script-ps1 = <<-EOT
      powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://storage.googleapis.com/${var.gcs_bucket}/install-docker-with-auto-start.ps1' -OutFile 'C:\\docker-startup.ps1'; Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File C:\\docker-startup.ps1'"
    EOT
  }

  tags = ["rdp", "winrm", "docker"]
}
