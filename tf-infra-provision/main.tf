module "cluster" {
  source               = "../tf-modules/cluster/"
  serviceprinciple_id  = var.serviceprinciple_id
  serviceprinciple_key = var.serviceprinciple_key
  location             = var.location
  kubernetes_version   = var.kubernetes_version
  ssh_key              = var.ssh_key
}