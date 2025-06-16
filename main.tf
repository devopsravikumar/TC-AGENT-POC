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

  metadata_startup_script_ps1 = file("${path.module}/install-docker-with-auto-start.ps1")

  tags = ["rdp", "winrm", "docker"]
}
