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
      image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20250514"
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
