#!/bin/sh
add-apt-repository -y ppa:vbernat/haproxy-1.8
apt-get update
apt-get -y install haproxy

tee -a /etc/haproxy/haproxy.cfg <<EOF

frontend webapp
    bind *:80
    mode http
    default_backend webapp

backend webapp
    mode http
    balance roundrobin
    http-send-name-header Host
    option forwardfor
    http-request set-header X-Forwarded-Host %[req.hdr(Host)]
${serverlist}

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

EOF

sed -i '/chroot/d' /etc/haproxy/haproxy.cfg
systemctl enable haproxy
systemctl restart haproxy
