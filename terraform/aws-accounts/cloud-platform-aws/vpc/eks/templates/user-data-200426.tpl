#!/bin/bash
set -o xtrace

DOCKERHUB_CREDS=$(aws ssm get-parameter \
  --name "/cloud-platform/infrastructure/account/dockerhub_credentials" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region eu-west-2)

mkdir -p "/root/.docker"
cat << EOF > /root/.docker/config.json
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "$DOCKERHUB_CREDS"
    }
  }
}
EOF

### The following sets the Garbage collection thresholds to clean up the container images cache at a specified percent of disk usage
KUBELET_CONFIG=/etc/kubernetes/kubelet/config.json

# Inject imageGCHighThresholdPercent value
echo "$(jq ".imageGCHighThresholdPercent=75" $KUBELET_CONFIG)" > $KUBELET_CONFIG

# Inject imageGCLowThresholdPercent value
echo "$(jq ".imageGCLowThresholdPercent=70" $KUBELET_CONFIG)" > $KUBELET_CONFIG

# Raise registryPullQPS and Burst value
echo "$(jq ".registryPullQPS=15" $KUBELET_CONFIG)" > $KUBELET_CONFIG
echo "$(jq ".registryBurst=30" $KUBELET_CONFIG)" > $KUBELET_CONFIG
EOF