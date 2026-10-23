module "kind" {
  source       = "./modules/kind"
  ns           = var.ns
  cluster_name = var.cluster_name
}

module "helm" {
  source     = "./modules/helm"
  depends_on = [module.kind]
}
