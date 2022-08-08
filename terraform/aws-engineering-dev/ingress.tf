resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress" {
  name = "nginx"
  # Do not replace this with other Nginx Ingress Controller.
  # It won't work: https://stackoverflow.com/a/71189536
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.2.0"
}
