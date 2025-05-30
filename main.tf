provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "teamcity_vm" {
  name         = "teamcity-vm"
  machine_type = "n1-standard-4"
  zone         = var.zone

  tags = ["teamcity"]

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-server-2022-dc"
      size  = 100
    }
  }

  network_interface {
    network    = "default"
    access_config {}  # External IP
  }

  metadata_startup_script = file("startup.ps1")

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
  }
}
