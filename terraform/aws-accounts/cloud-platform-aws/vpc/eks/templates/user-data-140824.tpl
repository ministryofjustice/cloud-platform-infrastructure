#!/bin/bash
set -o xtrace

mkdir -p "/root/.docker"
cat << EOF > /root/.docker/config.json
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "${dockerhub_credentials}"
    }
  }
}
EOF
mkdir -p "/var/lib/kubelet/.docker"
cat << EOF > /var/lib/kubelet/config.json
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "${dockerhub_credentials}"
    }
  }
}
EOF

### The following sets the Garbage collection thresholds to clean up the container images cache at a specified percent of disk usage
KUBELET_CONFIG=/etc/kubernetes/kubelet/kubelet-config.json

# Inject imageGCHighThresholdPercent value
echo "$(jq ".imageGCHighThresholdPercent=75" $KUBELET_CONFIG)" > $KUBELET_CONFIG

# Inject imageGCLowThresholdPercent value
echo "$(jq ".imageGCLowThresholdPercent=70" $KUBELET_CONFIG)" > $KUBELET_CONFIG
EOF