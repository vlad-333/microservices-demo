# resource "helm_release" "monitor" {
#   name            = "monitor-stack"
#   repository      = "https://prometheus-community.github.io/helm-charts"
#   chart           = "kube-prometheus-stack"
#   version         = "92.11.0"
#   namespace       = "monitor"
#   cleanup_on_fail = true
#   timeout         = 600
# }

resource "tls_private_key" "trust_anchor" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "trust_anchor" {
  private_key_pem       = tls_private_key.trust_anchor.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87600
  allowed_uses          = ["cert_signing", "crl_signing"]
  subject { common_name = "root.linkerd.cluster.local" }
}

resource "tls_private_key" "issuer" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer" {
  private_key_pem = tls_private_key.issuer.private_key_pem
  subject { common_name = "identity.linkerd.cluster.local" }
}

resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem      = tls_cert_request.issuer.cert_request_pem
  ca_private_key_pem    = tls_private_key.trust_anchor.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.trust_anchor.cert_pem
  is_ca_certificate     = true
  validity_period_hours = 8760
  allowed_uses          = ["cert_signing", "crl_signing"]
}

resource "helm_release" "linkerd_crds" {
  name             = "linkerd-crds"
  repository       = "https://helm.linkerd.io/edge"
  chart            = "linkerd-crds"
  namespace        = "linkerd"
  create_namespace = true
  version          = "2026.10.1"
}

resource "helm_release" "linkerd_control_plane" {
  name       = "linkerd-control-plane"
  repository = "https://helm.linkerd.io/edge"
  chart      = "linkerd-control-plane"
  namespace  = "linkerd"
  version    = "2026.10.1"
  timeout    = 600

  set_sensitive = [
    { name = "identityTrustAnchorsPEM", value = tls_self_signed_cert.trust_anchor.cert_pem },
    { name = "identity.issuer.tls.crtPEM", value = tls_locally_signed_cert.issuer.cert_pem },
    { name = "identity.issuer.tls.keyPEM", value = tls_private_key.issuer.private_key_pem },
  ]

  depends_on = [helm_release.linkerd_crds]
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
            managedNamespaceMetadata = {
              annotations = { "linkerd.io/inject" = "enabled" }
            }
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
                    podMonitorSelectorNilUsesHelmValues     = false
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
