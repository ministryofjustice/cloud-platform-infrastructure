#Spike Deploy to AWS or Kubernetes 

With the decision to move to concourse ci, the next question was where to deploy. AWS or Kubernetes.

##Reasons 
* Ease of deployment / making changes 
* Configuring with RDS
* Auto-scaling 
* Credential management 

###Ease of deployment
The deployment to AWS is far more complex than deploying to Kubernetes, which can be deployed using a Helm chart.
Though an interesting alternative way to deploy to AWS via [Concourse Up](https://github.com/EngineerBetter/concourse-up) this is still the double the code base of Helm deployment.

###Configuring with RDS
Exceptionally easy with Helm deployment, part of the chart.

###Credentials
Kubernetes has secret storage built in. Devs will have access to kube. Dev's can create service account. 

###Auto-scaling
Number of ways to add auto-scaling to an [AWS deployment](https://www.slideshare.net/mumoshu/autoscaled-concourse-ci-on-aws-wo-bosh). Upon speaking to the technical architect. Auto-scaling is a Kubernetes problem and the issue of auto-scaling does not need to be addressed has part of this decision. Assumption is that Kubernetes [Autoscaler](https://github.com/kubernetes/autoscaler) will control auto-scaling in the cluster.

##The decision 
Kubernetes for the win

##Deployment 

`helm install --namespace development --name concourse -f concourse.yaml stable/concourse`

Values changed in the yaml (from the default obtained with `helm inspect values stable/concourse`):
 * URL (otherwise auth redirects to the internal 127.0.0.1:8080)
 * worker size (to check if mem/cpu caused slowness in web interf)
 * Postgresql passw (not sure if actually a concern)
 * githubAuthClientId/githubAuthClientSecret for auth

`helm upgrade -f concourse.yaml concourse stable/concourse` 
