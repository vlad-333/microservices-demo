resource "helm_release" "monitor" {
  name       = "monitor-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "92.11.0"
  namespace  = "monitor"

  # set = [
  #   {
  #     name  = "namespace"
  #     value = "monitor"
  #   }
  # ]
}
