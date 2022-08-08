resource "helm_release" "metrics_server" {
  name = "metrics-server"
  # Do not replace this with other Nginx Ingress Controller.
  # It won't work: https://stackoverflow.com/a/71189536
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "6.0.0"

  set {
    name  = "apiService.create"
    value = "true"
  }
}
