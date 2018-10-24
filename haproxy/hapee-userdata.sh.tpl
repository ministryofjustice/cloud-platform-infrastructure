#!/bin/sh
tee /etc/hapee-1.7/hapee-lb.cfg <<EOF
global
    log                127.0.0.1 local0
    log                127.0.0.1 local1 notice
    user               hapee-lb
    group              hapee
    chroot             /var/empty
    pidfile            /var/run/hapee-1.7/hapee-lb.pid
    stats socket       /var/run/hapee-1.7/hapee-lb.sock user hapee-lb group hapee mode 660 level admin
    stats timeout      10m
    module-path        /opt/hapee-1.7/modules
    daemon

defaults
    mode               http
    log                global
    option             httplog
    option             dontlognull
    option             forwardfor except 127.0.0.0/8
    option             redispatch
    retries            3
    timeout connect    10s
    timeout client     300s
    timeout server     300s

listen webapp
    bind *:80          accept-proxy
    balance            roundrobin
    http-send-name-header Host
    server demo.apps.cloud-platform-test-0.k8s.integration.dsd.io demo.apps.cloud-platform-test-0.k8s.integration.dsd.io:443 check ssl verify none weight 30
    server demo.apps.cloud-platform-live-0.k8s.integration.dsd.io demo.apps.cloud-platform-live-0.k8s.integration.dsd.io:443 check ssl verify none weight 70

# frontend https_frontend
#    bind *:443 ssl crt-list /etc/ssl/mycerts.txt

frontend health
    bind *:8080
    acl backend_dead nbsrv(webapp) lt 1
    monitor-uri /haproxy_status
    monitor fail if backend_dead

listen stats
  bind *:9000
  mode http
  stats enable
  stats realm Haproxy\ Statistics  # Title text for popup window
  stats uri /
  stats auth user:pass

EOF
systemctl restart hapee-1.7-lb
