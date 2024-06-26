# To be run from localhost machine
terraform {
  required_providers {
    openstack = {
        source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  cloud = "openstack" # defined in ~/.config/openstack/clouds.yaml
}

resource "openstack_compute_instance_v2" "ysi-puppet-master" {
  name            = "ysi-puppet-master"
  image_name      = "Ubuntu-24.04-LTS"
  flavor_name     = "C4R6_10G"
  key_pair        = "ysi"
  security_groups = ["sshOslomet"]

  network {
    name = "acit"
  }

  provisioner "file" {
    source      = "/home/ysi/.ssh/id_ed25519"
    destination = "/home/ubuntu/.ssh/id_ed25519"

    connection {
      host        = self.access_ip_v4
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_ed25519")
    }

  }

  # Authentication in /home/ubuntu/.config/openstack/clouds.yaml
  provisioner "file" {
    source      = "/home/ysi/.config"
    destination = "/home/ubuntu/.config"

    connection {
      host        = self.access_ip_v4
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_ed25519")
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = self.access_ip_v4
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_ed25519")
    }

    inline = [

      # Configuring ssh file permissions
      "sudo chmod 0400 /home/ubuntu/.ssh/id_ed25519",

      # Installing Terraform
      "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt update && sudo apt install terraform",
      "terraform --version",

      # Installing Openstack command line interaction
      "sudo NEEDRESTART_MODE=a apt install python3-pip -y",
      "pip --version",
      "pip install openstackclient",
      "echo \"export OS_CLOUD=openstack\" >> /home/ubuntu/.bashrc",
      "openstack --version",

      # Installing Puppet
      "curl -LO https://apt.puppet.com/puppet8-release-jammy.deb",
      "sudo dpkg -i ./puppet8-release-jammy.deb",
      "sudo apt update",
      "sudo apt install -y puppetserver",
    ]
  }
}

output "ysi-puppet-master" {
  value = openstack_compute_instance_v2.ysi-puppet-master.access_ip_v4
}