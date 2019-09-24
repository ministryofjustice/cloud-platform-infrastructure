resource "helm_release" "eventrouter" {
  name      = "eventrouter"
  chart     = "stable/eventrouter"
  namespace = "logging"

  set {
    name  = "sink"
    value = "stdout"
  }

  depends_on = ["helm_release.fluentd"]
}
