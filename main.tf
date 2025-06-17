provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "docker_vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnet
    access_config {}
  }

  service_account {
    email  = var.service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = var.tags

  metadata_startup_script = file("install-docker-ce-with-autostart.ps1")

  metadata = {
    windows-startup-script-ps1 = <<-EOT
      net user Administrator "${var.admin_password}"
      netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
      powershell -ExecutionPolicy Bypass -File install-docker-ce-with-autostart.ps1
    EOT
  }
}

output "vm_instance_name" {
  value = google_compute_instance.docker_vm.name
}

