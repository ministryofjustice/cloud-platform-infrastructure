## Cloud Platform: How to perform a DNS failover
This document will walk you through the process of performing a DNS failover for services on the Cloud-Platform. 

It is assumed that:
- You have a failed cluster.
- You have spun up a working cluster.
- You have a Route53 Application Load Balancer (Classic Load Balancers [do not allow multi-certificates](https://aws.amazon.com/blogs/aws/new-application-load-balancer-sni/))

### Scenario
The Live cluster has failed and key services are unavailable to users. 

To perform a failover a new cluster has been [created](https://github.com/ministryofjustice/kubernetes-investigations/blob/master/Create-Cluster.md) and relevant applications/namespaces have been replicated successfully. 

### Cluster re-direct via Route 53
- Open your AWS console and navigate to *Route 53 > Hosted Zones*
- Find the failed cluster entry e.g. live-cluster.k8s.integration.dsd.io and open your record sets.
- Find the wildcard Alias record with the prefix `*.apps` and change the Alias target to the DNS name of your new Application Load Balancer. It will look something like:
*example-hash-3433434.eu-west-1.elb.amazonaws.com*

### Ensure the certificate exists on the new load balancer
 - Open your AWS console and navigate to *EC2 > Load Balancers*
 - Find your new load balancer and click on the 'Listeners' tab
 - Under the 'HTTPS : 443' option view/edit certificates
 - Using the drop down, add the certificate of the failed cluster ensuring the new cluster certificate remains as the default certificate

### Create/Amend the Ingress Rule
> On the new cluster you'll need to amend any ingress rules to allow your URL to point to the relevant service. 
- Amend the ingress rule using the command `kubectl edit ingress <ingressRule>`. The value that needs changing is `host`
- This can also be achieved by creating a manifest file and applying using `kubectl create -f <manifest.yaml>`



