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
