module "kind" {
  source       = "./modules/kind"
  cluster_name = var.cluster_name
}
