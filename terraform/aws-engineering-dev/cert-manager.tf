resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name = "cert-manager"
  # Do not replace this with other Nginx Ingress Controller.
  # It won't work: https://stackoverflow.com/a/71189536
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.8.0"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-prod"
  }

}
