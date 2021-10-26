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

resource "hcloud_ssh_key" "laznp-kube" {
  name = "laznp-kube"
  public_key = file("~/.ssh/laznp-kube.pub")
}

resource "hcloud_network" "kube-network" {
  name     = "kube-network"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "kube-network-subnet" {
  network_id   = hcloud_network.kube-network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.240.0.0/24"
}

resource "hcloud_server" "kube-master" {
  count = var.instance_count
  name = "controller-${count.index}"
  server_type = "cx11"
  image = "ubuntu-18.04"
  location = "fsn1"
  ssh_keys = [hcloud_ssh_key.laznp-kube.id]
}

resource "hcloud_server_network" "kube-master-network" {
  count = var.instance_count
  server_id  = hcloud_server.kube-master[count.index].id
  network_id = hcloud_network.kube-network.id
  ip         = "10.240.0.1${count.index}"
}

resource "hcloud_server" "kube-slave" {
  count = var.instance_count
  name = "worker-${count.index}"
  server_type = "cx11"
  image = "ubuntu-18.04"
  location = "fsn1"
  ssh_keys = [hcloud_ssh_key.laznp-kube.id]
}

resource "hcloud_server_network" "kube-slave-network" {
  count = var.instance_count
  server_id  = hcloud_server.kube-slave[count.index].id
  network_id = hcloud_network.kube-network.id
  ip         = "10.240.0.2${count.index}"
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

resource "hcloud_load_balancer_service" "kube-lb-service" {
    load_balancer_id = hcloud_load_balancer.kube-lb.id
    protocol         = "tcp"
    listen_port      = 6443
    destination_port = 6443
}
