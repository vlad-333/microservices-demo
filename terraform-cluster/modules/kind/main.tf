resource "kind_cluster" "default" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    node {
      role = "control-plane"
    }
    node {
      role = "worker"
    }
  }
}

resource "kubernetes_namespace_v1" "namespace" {
  for_each = toset(var.ns)
  metadata {
    name = each.key
  }
  depends_on = [kind_cluster.default]
}
