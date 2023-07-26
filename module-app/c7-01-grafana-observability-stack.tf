resource "null_resource" "deploy_grafana_script" {
  depends_on = [helm_release.external_dns] 
  provisioner "local-exec" {
    command = "cd ${path.module}/grafana-observability-stack && sh deploy.sh"
  }
}