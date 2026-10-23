output "endpoint" {
  value = kind_cluster.default.endpoint
}
output "client_certificate" {
  value     = kind_cluster.default.client_certificate
  sensitive = true
}
output "client_key" {
  value     = kind_cluster.default.client_key
  sensitive = true
}
output "cluster_ca_certificate" {
  value     = kind_cluster.default.cluster_ca_certificate
  sensitive = true
}
