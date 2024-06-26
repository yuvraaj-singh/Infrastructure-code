# To be run from localhost machine
resource "openstack_compute_instance_v2" "ysi-puppet-slave" {
  name            = "ysi-puppet-slave"
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

      # Installing Puppet
      "curl -LO https://apt.puppet.com/puppet8-release-jammy.deb",
      "sudo dpkg -i ./puppet8-release-jammy.deb",
      "sudo apt update",
      "sudo apt install -y puppetserver",
    ]
  }
}

output "ysi-puppet-slave" {
  value = openstack_compute_instance_v2.ysi-puppet-slave.access_ip_v4
}