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

resource "hcloud_network" "kube-network" {
  name     = "kube-network"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "kube-network-subnet" {
  network_id   = hcloud_network.kube-network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_ssh_key" "zoelabs" {
  name = "ZoeLabs"
  public_key = file("~/.ssh/zoelabs.pub")
}

resource "hcloud_server" "kube-master" {
  count = var.instance_count
  name = "kube-master-${count.index}"
  server_type = "cx11"
  image = "ubuntu-18.04"
  location = "fsn1"
  ssh_keys = [hcloud_ssh_key.zoelabs.id]
}

resource "hcloud_server_network" "kube-master-network" {
  count = var.instance_count
  server_id  = hcloud_server.kube-master[count.index].id
  network_id = hcloud_network.kube-network.id
  ip         = "10.0.1.1${count.index}"
}

resource "hcloud_server" "kube-slave" {
  count = var.instance_count
  name = "kube-slave-${count.index}"
  server_type = "cx11"
  image = "ubuntu-18.04"
  location = "fsn1"
  ssh_keys = [hcloud_ssh_key.zoelabs.id]
}

resource "hcloud_server_network" "kube-slave-network" {
  count = var.instance_count
  server_id  = hcloud_server.kube-slave[count.index].id
  network_id = hcloud_network.kube-network.id
  ip         = "10.0.1.2${count.index}"
}

resource "hcloud_load_balancer" "kube-lb" {
  name               = "kube-lb"
  load_balancer_type = "lb11"
  location           = "fsn1"
}

resource "hcloud_load_balancer_target" "kube-lb-target" {
  count            = var.instance_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.kube-lb.id
  server_id        = hcloud_server.kube-master[count.index].id
}
