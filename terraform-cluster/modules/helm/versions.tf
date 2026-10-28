terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.4"
    }
  }
}
