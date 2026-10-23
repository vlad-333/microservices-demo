variable "cluster_name" {
  default = "demo"
}

variable "ns" {
  default = ["monitor", "boutique"]
  type    = list(string)
}
