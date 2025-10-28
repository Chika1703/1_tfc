# --- VPC ---
resource "twc_vpc" "main" {
  name        = "netology-vpc"
  subnet_v4   = "192.168.0.0/16"
  description = "VPC for NAT test"
  location    = "ru-1"
}

# --- Floating ip для NAT ---
resource "twc_floating_ip" "nat_ip" {
  availability_zone = "spb-3"
  ddos_guard        = false
}

# --- NAT сервер ---
resource "twc_server" "nat" {
  name                     = "nat-instance"
  preset_id                = 2447
  os_id                    = 99
  project_id               = var.project_id
  availability_zone        = "spb-3"
  ssh_keys_ids             = [var.ssh_key_id]
  floating_ip_id           = twc_floating_ip.nat_ip.id
  is_root_password_required = false

  local_network {
    id = twc_vpc.main.id
    ip = "192.168.10.254"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "sudo apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent",
      "sudo iptables -t nat -A POSTROUTING -s 192.168.20.0/24 -o eth0 -j MASQUERADE",
      "sudo iptables -A FORWARD -s 192.168.20.0/24 -o eth0 -j ACCEPT",
      "sudo iptables -A FORWARD -d 192.168.20.0/24 -m state --state ESTABLISHED,RELATED -i eth0 -j ACCEPT",
      "sudo netfilter-persistent save"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = twc_floating_ip.nat_ip.ip
    }
  }
}

# --- Приватная ВМ ---
resource "twc_server" "private" {
  name                     = "private-vm"
  preset_id                = 2447
  os_id                    = 99
  project_id               = var.project_id
  availability_zone        = "spb-3"
  ssh_keys_ids             = [var.ssh_key_id]
  is_root_password_required = false

  local_network {
    id = twc_vpc.main.id
    ip = "192.168.20.10"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf",
      "echo 'nameserver 1.1.1.1' | sudo tee -a /etc/resolv.conf",
      "sudo systemctl restart systemd-resolved",
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = twc_server.private.local_network[0].ip
      bastion_host = twc_floating_ip.nat_ip.ip
      bastion_user = "root"
      bastion_private_key = file("~/.ssh/id_rsa")
    }
  }
}

# --- Вывод ip ---
output "nat_public_ip" {
  value = twc_floating_ip.nat_ip.ip
}

output "private_ip" {
  value = twc_server.private.local_network[0].ip
}
