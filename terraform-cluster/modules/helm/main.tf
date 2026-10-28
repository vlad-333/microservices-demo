# resource "helm_release" "monitor" {
#   name            = "monitor-stack"
#   repository      = "https://prometheus-community.github.io/helm-charts"
#   chart           = "kube-prometheus-stack"
#   version         = "92.11.0"
#   namespace       = "monitor"
#   cleanup_on_fail = true
#   timeout         = 600
# }

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

        monitoring = {
          namespace = "argo"
          project   = "default"
          source = {
            repoURL        = "https://prometheus-community.github.io/helm-charts"
            chart          = "kube-prometheus-stack"
            targetRevision = "92.11.0"
            helm = {
              releaseName = "monitor-stack"
              valuesObject = {
                prometheus = {
                  prometheusSpec = {
                    retention                               = "3d"
                    serviceMonitorSelectorNilUsesHelmValues = false
                    resources = {
                      requests = { cpu = "100m", memory = "512Mi" }
                      limits   = { memory = "1536Mi" }
                    }
                  }
                }
                grafana = {
                  enabled = true
                  resources = {
                    requests = { memory = "256Mi" }
                    limits   = { memory = "512Mi" }
                  }
                }
                alertmanager = {
                  alertmanagerSpec = {
                    resources = {
                      requests = { memory = "32Mi" }
                      limits   = { memory = "128Mi" }
                    }
                  }
                }
                sidecar = {
                  resources = {
                    requests = { memory = "64Mi" }
                    limits   = { memory = "128Mi" }
                  }
                }
                kubeEtcd              = { enabled = false }
                kubeScheduler         = { enabled = false }
                kubeControllerManager = { enabled = false }
                kubeProxy             = { enabled = false }
              }
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "monitor"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true",
              "ServerSideApply=true",
            ]
          }
        }

        blackbox = {
          namespace = "argo"
          project   = "default"
          source = {
            repoURL        = "https://prometheus-community.github.io/helm-charts"
            chart          = "prometheus-blackbox-exporter"
            targetRevision = "11.0.0"
            helm = {
              releaseName = "blackbox"
              valuesObject = {
                serviceMonitor = {
                  enabled = true
                  targets = [
                    {
                      name     = "frontend"
                      url      = "http://frontend.boutique.svc:80"
                      interval = "30s"
                      module   = "http_2xx"
                    }
                  ]
                }
              }
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "monitor"
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
