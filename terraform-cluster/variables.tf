variable "cluster_name" {
  default = "demo"
}

variable "ns" {
  default = ["monitor", "argo", "boutique"]
  type    = list(string)
}
