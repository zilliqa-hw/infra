locals {
  network_cidrs = {
    rfc1918 = [
      "192.168.0.0/16",
      "172.16.0.0/12",
      "10.0.0.0/8",
    ]
  }
}