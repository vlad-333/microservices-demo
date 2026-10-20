# modules/kind/versions.tf  (loose: only what the module truly needs)
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.11"
    }
  }
}
