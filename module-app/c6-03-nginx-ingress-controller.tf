resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "default"
  create_namespace = true

  provisioner "local-exec" {
    command = <<EOF
      echo "Waiting for the nginx ingress controller pods"
      kubectl wait --namespace default \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s
      echo "Nginx ingress controller successfully started"
    EOF
  }
}