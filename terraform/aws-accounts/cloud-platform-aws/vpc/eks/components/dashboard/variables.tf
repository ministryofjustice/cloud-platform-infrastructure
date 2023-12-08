variable "cluster_domain_name" {
  description = "The cluster domain - used by externalDNS and certmanager to create URLs"
}

variable "oidc_components_client_id" {
  description = "OIDC ClientID used to authenticate to Grafana, AlertManager and Prometheus (oauth2-proxy)"
}

variable "oidc_components_client_secret" {
  description = "OIDC ClientSecret used to authenticate to Grafana, AlertManager and Prometheus (oauth2-proxy)"
}

variable "oidc_issuer_url" {
  description = "Issuer URL used to authenticate to Grafana, AlertManager and Prometheus (oauth2-proxy)"
}

variable "dependence_ingress_controller" {
  description = "Ingress controller module dependences in order to be executed."
  type        = list(string)
}