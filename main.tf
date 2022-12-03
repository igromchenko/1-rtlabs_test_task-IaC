terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "ТУТ НЕОБХОДИМО УКАЗАТЬ СВОЙ OAuth ТОКЕН"
  cloud_id  = "ТУТ НЕОБХОДИМО УКАЗАТЬ СВОЙ cloud_id"
  folder_id = "ТУТ НЕОБХОДИМО УКАЗАТЬ СВОЙ folder_id"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "srv" {
  name = "srv"
  platform_id = "standard-v2"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = 2
    memory = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8pqqqelpfjceogov30"
      size = 6
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    ip_address = "192.168.0.101"
    nat = true
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

resource "yandex_compute_instance" "k8s-master" {
  name = "k8s-master"
  platform_id = "standard-v2"

  scheduling_policy {
    preemptible = true
  }
  
  resources {
    cores  = 2
    memory = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8pqqqelpfjceogov30"
      size = 4
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    ip_address = "192.168.0.102"
    nat = true
  }
  
  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

resource "yandex_compute_instance" "k8s-worker" {
  name = "k8s-worker"
  platform_id = "standard-v2"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = 2
    memory = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8pqqqelpfjceogov30"
      size = 6
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    ip_address = "192.168.0.103"
    nat = true
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.0.0/24"]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tpl",
    {
      server_ip = yandex_compute_instance.srv.network_interface.0.nat_ip_address
      master_node_ip = yandex_compute_instance.k8s-master.network_interface.0.nat_ip_address
      worker_node_ip = yandex_compute_instance.k8s-worker.network_interface.0.nat_ip_address
    }
  )
  filename = "inventory"
}

resource "null_resource" "Ansible" {

  provisioner "local-exec" {
    command = "./provisioning.sh  ${yandex_compute_instance.srv.network_interface.0.nat_ip_address} ${yandex_compute_instance.k8s-master.network_interface.0.nat_ip_address} ${yandex_compute_instance.k8s-worker.network_interface.0.nat_ip_address}"
  }
}

output "WORKER-NODE" {
  value = "KUBERNETES CLUSTER SUCCESSFULLY DEPLOYED! Connect to its worker node by executing: ssh igromchenko@${yandex_compute_instance.k8s-worker.network_interface.0.nat_ip_address}"
}

output "MASTER-NODE" {
  value = "KUBERNETES CLUSTER SUCCESSFULLY DEPLOYED! Connect to its control plane by executing: ssh igromchenko@${yandex_compute_instance.k8s-master.network_interface.0.nat_ip_address}"
}

output "SERVER" {
  value = "GITLAB/MONITORING SERVER SUCCESSFULLY DEPLOYED! Connect to its console by executing: ssh igromchenko@${yandex_compute_instance.srv.network_interface.0.nat_ip_address}"
}
