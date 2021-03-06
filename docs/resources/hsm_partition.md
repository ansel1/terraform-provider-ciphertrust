---
# generated by https://github.com/hashicorp/terraform-plugin-docs
page_title: "ciphertrust_hsm_partition Resource - terraform-provider-ciphertrust"
subcategory: ""
description: |-

---

# ciphertrust_hsm_partition (Resource)

A HSM-Luna partition is required to manage HSM-Luna keys.

## Example Usage

```hcl
resource "ciphertrust_hsm_server" "hsm_server" {
  hostname        = var.hsm_hostname
  hsm_certificate = var.hsm_certificate
}

resource "ciphertrust_hsm_connection" "hsm_connection" {
  hostname    = var.hsm_hostname
  server_id   = ciphertrust_hsm_server.hsm_server.id
  name        = "hsm_connection_name"
  partitions  {
    partition_label = "partition_label"
    serial_number   = "serial_number"
  }
  partition_password = "hsm_partition_password"
}

resource "ciphertrust_hsm_partition" "hsm_partition" {
  hsm_connection = ciphertrust_hsm_connection.hsm_connection.id
}
```

<!-- schema generated by tfplugindocs -->
## Schema

### Optional

- **hsm_connection** (String) Name or ID of the HSM connection.

### Read-Only

- **id** (String) CipherTrust HSM partition ID.


