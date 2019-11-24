###############
# EventRouter #
###############

#
# HELM
#

resource "helm_release" "eventrouter" {
  count = var.enable_eventrouter ? 1 : 0

  name      = "eventrouter"
  chart     = "stable/eventrouter"
  namespace = "logging"

  set {
    name  = "sink"
    value = "stdout"
  }

  depends_on = [ helm_release.fluentd_es ]
}
