---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry-cache-service
  namespace: docker-registry-cache
  labels:
    app: docker-registry-cache
spec:
  ports:
  - port: 5000
    name: http
    targetPort: 5000
  selector:
    app: docker-registry-cache
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: docker-registry-cache-ingress
  namespace: docker-registry-cache
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",", [for ip in nat_gateway_ips : "${ip}/32"])}
spec:
  tls:
  - hosts:
    - docker-registry-cache.apps.${cluster_name}.cloud-platform.service.justice.gov.uk
  rules:
  - host: docker-registry-cache.apps.${cluster_name}.cloud-platform.service.justice.gov.uk
    http:
      paths:
      - path: /
        backend:
          serviceName: docker-registry-cache-service
          servicePort: 5000
