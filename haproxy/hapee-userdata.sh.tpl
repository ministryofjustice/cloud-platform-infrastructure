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
    cookie             SERVERID insert indirect nocache
${serverlist}

frontend health
    bind *:8080
    acl backend_dead nbsrv(webapp) lt 1
    monitor-uri /haproxy_status
    monitor fail if backend_dead
EOF
systemctl restart hapee-1.7-lb
