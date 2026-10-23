resource "helm_release" "monitor" {
  name            = "monitor-stack"
  repository      = "https://prometheus-community.github.io/helm-charts"
  chart           = "kube-prometheus-stack"
  version         = "92.11.0"
  namespace       = "monitor"
  cleanup_on_fail = true
  timeout         = 600
}

resource "helm_release" "argo" {
  name            = "argo-cd"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argo-cd"
  version         = "10.10.5"
  namespace       = "argo"
  values          = [file("${path.module}/values/argo-values.yaml")]
  cleanup_on_fail = true
  timeout         = 600
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  namespace  = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.7"
  values = [
    yamlencode({
      applications = {
        online-boutique = {
          namespace = "argo"
          project   = "default"
          source = {
            repoURL        = "https://github.com/vlad-333/microservices-demo.git"
            targetRevision = "dev"
            path           = "helm-chart"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "boutique"
          }
          syncPolicy = {
            automated   = { prune = true, selfHeal = true }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.argo]
}
