terraform {
  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "~> 1.4.2"
    }
  }
}

provider "multipass" {}

# Control plane
resource "multipass_instance" "k3s_master" {
  name   = var.vm_names.master
  cpus   = var.master_cpus
  memory = var.master_memory
  disk   = var.master_disk
  image  = var.vm_image
}

# Worker node
resource "multipass_instance" "k3s_worker" {
  name   = var.vm_names.worker
  cpus   = var.worker_cpus
  memory = var.worker_memory
  disk   = var.worker_disk
  image  = var.vm_image
}

# Docker Registry server
resource "multipass_instance" "docker_registry" {
  name   = var.vm_names.registry
  cpus   = var.registry_cpus
  memory = var.registry_memory
  disk   = var.registry_disk
  image  = var.vm_image
}

# read the master VM after creation
data "multipass_instance" "k3s_master" {
  name = multipass_instance.k3s_master.name
}

# read the worker VM after creation
data "multipass_instance" "k3s_worker" {
  name = multipass_instance.k3s_worker.name
}

# read the registry VM after creation
data "multipass_instance" "docker_registry" {
  name = multipass_instance.docker_registry.name
}