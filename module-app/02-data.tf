
data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_id
}
data "kubernetes_service_v1" "ingress_nginx" {

  metadata {
    name      = "ingress-nginx"
    namespace = "default"
  }
  depends_on = [
    helm_release.nginx_ingress
  ]
}