terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.4"
    }
  }
}
