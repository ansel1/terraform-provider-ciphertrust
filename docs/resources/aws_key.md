---
# generated by https://github.com/hashicorp/terraform-plugin-docs
page_title: "ciphertrust_aws_key Resource - terraform-provider-ciphertrust"
subcategory: ""
description: |-

---

# ciphertrust_aws_key (Resource)

This resource provides for the following:

- Creating an AWS key in AWS
- Creating an AWS key by uploading an existing DSM or CipherTrust CM key
- Creating an AWS key without key material and importing key material from a DSM key or CipherTrust CM key.

Optionally a key can be scheduled for rotation using either a DSM key or a CipherTrust CM key as the source for the new key.

## Example Usage

The following examples assume this script snippet as a prefix

```hcl
resource "ciphertrust_aws_connection" "connection" {
  name = "aws_connection_name"
}

data "ciphertrust_aws_account_details" "account_details" {
  aws_connection = ciphertrust_aws_connection.connection.id
}

resource "ciphertrust_aws_kms" "kms" {
  account_id     = data.ciphertrust_aws_account_details.account_details.account_id
  aws_connection = ciphertrust_aws_connection.connection.id
  name           = "kms_name"
  regions        = ["us-east-1"]
}
```

### Basic Create Key Usage

This example creates a key in AWS.

```hcl
resource "ciphertrust_aws_key" "aws_key" {
  alias                      = ["key_name"]
  kms                        = ciphertrust_aws_kms.kms.id
  region                     = "us-east-1"
}
```

### Upload Key Usage

This example uploads a CipherTrust CM key to AWS.

```hcl
resource "ciphertrust_cm_key" "local_key" {
  name      = "local_key_name"
  algorithm = "AES"
}

resource "ciphertrust_aws_key" "aws_key" {
  alias  = ["key_name"]
  kms    = ciphertrust_aws_kms.kms.id
  region = "us-east-1"
  upload_key {
    source_key_identifier = ciphertrust_cm_key.local_key.id
  }
}
```

### Import Key Material Usage

This example imports key material from a CipherTrust CM key to an AWS CMK that is created without key material.

```hcl
resource "ciphertrust_aws_key" "aws_key" {
  alias = ["key_name"]
  import_key_material {
    source_key_name = "local_key_name"
  }
  kms    = ciphertrust_aws_kms.kms.id
  origin = "EXTERNAL"
  region = "us-east-1"
}

```

### Enable Key Rotation Usage


This example schedules a key for rotation using a DSM as the key source.

```hcl
resource "ciphertrust_scheduler" "rotation_job" {
  key_rotation_params {
    cloud_name = "aws"
  }
  name       = "scheduled_rotation_name"
  run_at     = "0 23 * * *"
}

resource "ciphertrust_dsm_connection" "dsm_connection" {
  name = "dsm_connection_name"
  nodes {
    hostname    = "10.123.45.6"
    certificate = "dsm_server.pem"
  }
  password = "dsm_password"
  username = "dsm_username"
}

resource "ciphertrust_dsm_domain" "dsm_domain" {
  dsm_connection = ciphertrust_dsm_connection.dsm_connection.id
  domain_id      = 1234
}

resource "ciphertrust_aws_key" "aws_key" {
  alias = [local.alias]
  enable_rotation {
    disable_encrypt = true
    dsm_domain_id   = ciphertrust_dsm_domain.dsm_domain.id
    job_config_id   = ciphertrust_scheduler.rotation_job.id
    key_source      = "dsm"
  }
  kms    = ciphertrust_aws_kms.kms.id
  origin = "AWS_KMS"
  region = "us-east-1"
}
```

<!-- schema generated by tfplugindocs -->
## Schema

### Required

- **alias** (Set of String) Alias(es) of the key
- **kms** (String) Name or ID of the kms.
- **region** (String) AWS region in which to create a key.

### Optional

- **auto_rotate** (Boolean) Enable AWS autorotation on the key. Default is false.
- **bypass_policy_lockout_safety_check** (Boolean) Bypass the AWS key policy lockout safety check. Default is false.
- **customer_master_key_spec** (String) Specifies a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms the key supports. Valid values: SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521 and ECC_SECG_P256K1. Default is SYMMETRIC_DEFAULT.
- **description** (String) Description of the AWS key.
- **enable_key** (Boolean) Enable or disable the key. Default is true.
- **enable_rotation** (Block List, Max: 1) Enable the key for scheduled rotation job. (see [below for nested schema](#nestedblock--enable_rotation))
- **import_key_material** (Block List, Max: 1) Key import details. (see [below for nested schema](#nestedblock--import_key_material))
- **key_policy** (Block List, Max: 1) Key policy to attach to the AWS key. If not specified the key will have a default policy. (see [below for nested schema](#nestedblock--key_policy))
- **key_usage** (String) Specifies the intended use of the key. RSA key options: ENCRYPT_DECRYPT, SIGN_VERIFY. Default is ENCRYPT_DECRYPT. EC key options: SIGN_VERIFY. Default is SIGN_VERIFY. Symmetric key options: ENCRYPT_DECRYPT. Default is ENCRYPT_DECRYPT.
- **origin** (String) Source of the CMK's key material.  Options: AWS_KMS, EXTERNAL. Defaults to AWS_KMS. AWS_KMS will create an AWS key with key material. EXTERNAL will create an AWS key with no key material and is required to import key material.
- **schedule_for_deletion_days** (Number) Waiting period after the key is destroyed before the key is deleted. Default is 7.
- **tags** (Map of String) A list of key:value pairs to assign to the key.
- **upload_key** (Block List, Max: 1) Key upload details. (see [below for nested schema](#nestedblock--upload_key))

### Read-Only

- **arn** (String) The Amazon Resource Name (ARN) of the key.
- **id** (String) AWS Key ID.
- **key_id** (String) CipherTrust Key ID.

<a id="nestedblock--enable_rotation"></a>
### Nested Schema for `enable_rotation`

Required:

- **job_config_id** (String) ID of the scheduler job that will perform key rotation.
- **key_source** (String) Source of the key material. Options: dsm, ciphertrust.

Optional:

- **disable_encrypt** (Boolean) Disable encryption on the old key.
- **dsm_domain_id** (String) DSM domain ID, required if key_source is dsm.


<a id="nestedblock--import_key_material"></a>
### Nested Schema for `import_key_material`

Required:

- **source_key_name** (String) Name of the key created for key material.

Optional:

- **dsm_domain_id** (String) Domain for the DSM key. Required if source_key_tier is dsm.
- **key_expiration** (Boolean) Enable key expiration.
- **source_key_tier** (String) Source of the key. Options: local and dsm. Default is local.
- **valid_to** (String) Date of key expiry in UTC time in RFC3339 format. For example, 2022-07-03T14:24:00Z.


<a id="nestedblock--key_policy"></a>
### Nested Schema for `key_policy`

Optional:

- **external_accounts** (List of String) Policy and key administrators, key_users, and AWS accounts are mutually exclusive. Specify either the policy or any one user at a time. If no parameters are specified, the default policy is used.
- **key_admins** (List of String) Policy and key administrators, key_users, and AWS accounts are mutually exclusive. Specify either the policy or any one user at a time. If no parameters are specified, the default policy is used.
- **key_users** (List of String) Policy and key administrators, key_users, and AWS accounts are mutually exclusive. Specify either the policy or any one user at a time. If no parameters are specified, the default policy is used.
- **policy** (String) Policy and key administrators, key_users, and AWS accounts are mutually exclusive. Specify either the policy or any one user at a time. If no parameters are specified, the default policy is used.


<a id="nestedblock--upload_key"></a>
### Nested Schema for `upload_key`

Required:

- **source_key_identifier** (String) DSM or CipherTrust key ID to upload to AWS.

Optional:

- **key_expiration** (Boolean) Enable key expiration.
- **source_key_tier** (String) Source of the key. Options: local and dsm. Default is local.
- **valid_to** (String) Date of key expiry in UTC time in RFC3339 format. for example, 2022-07-03T14:24:00Z.


