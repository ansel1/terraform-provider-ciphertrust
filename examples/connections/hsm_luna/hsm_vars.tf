variable "hsm_certificate" {
  type    = string
  default = "../../server_certs/hsm-server.pem"
}

variable "hsm_hostname" {
  type    = string
  default = "10.164.10.35"
}

variable "hsm_partition_password" {
  type    = string
  default = "userpin1"
}

variable "hsm_partitions" {
  type = list(object({ partition_label = string, serial_number = string }))
  default = [
    {
      partition_label = "cckm1"
      serial_number   = "1461468362998"
    },
  ]
}



