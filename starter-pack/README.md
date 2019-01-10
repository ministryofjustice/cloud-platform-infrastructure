# Starter Pack

## Overview
This starter-pack is a collection of three applications designed to be quickly deployed on a new test cluster to validate its functionality.

## Applications

### Demo Reference App
The full repository of this application can be found [here](https://github.com/kubernetes/kops/).

The ingress object within `demo-deploy.yaml` must be modified to match the cluster you're deploying to.

NOTE: The application can sometimes display a 504 error when it's first deployed. To mitigate this, simply kill the migration pod.

### Wordpress
This starter pack includes basic installation of Wordpress.

The ingress object within `wp-deploy.yaml` must be modified to match the cluster you're deploying to.

NOTE: When Wordpress is deployed, it will display the initial setup page on its URL. You must configure an admin account, otherwise, anyone in the public domain may hijack it.

### HTTPbin

Httpbin is a simple HTTP request and response service.

The ingress object within `httpbin-deploy.yaml` must be modified to match the cluster you're deploying to.