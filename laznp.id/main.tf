terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.31.1"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_token
}

resource "hcloud_ssh_key" "zoelabs" {
  name = "ZoeLabs"
  public_key = file("~/.ssh/zoelabs.pub")
}

resource "hcloud_server" "laznp" {
  name = "laznp.id"
  server_type = "cx21"
  image = "ubuntu-18.04"
  location = "fsn1"
  keep_disk = false
  labels = {
    "Kubernetes" = ""
    "ZoeLabs" = ""
  }
}
