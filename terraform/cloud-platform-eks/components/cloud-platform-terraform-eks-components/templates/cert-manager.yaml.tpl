ingressShim:
  defaultIssuerName: letsencrypt-production
  defaultIssuerKind: ClusterIssuer
  defaultACMEChallengeType: dns01
  defaultACMEDNS01ChallengeProvider: route53-cloud-platform

securityContext:
  enabled: false

podAnnotations:
  iam.amazonaws.com/role: "${iam_role}"
