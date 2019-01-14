## Cloud Platform DR
The cloud-platform-dr directory contains Terraform code to be used in a disaster recovery scenario to restore resources / data

### etcd_ebs.tf

This Terraform file identifies and restores the latest snapshots for each of the 6 etcd ebs volumes used in a 3 master cluster. 

Step 1:

Identify and either remove the tags on each of the etcd ebs volumes or rename them. This is because the restored volumes will be created with the exact same tags and that [protokube](https://github.com/kubernetes/kops/tree/master/protokube) can discover and mount the new ebs volumes to the cluster. Click [HERE](https://github.com/kubernetes/kops/blob/master/docs/etcd_backup.md#restore-volume-backups) for more info.

Step 2:

Reboot all master nodes so the volumes unmount

Step 3:

### Set environment variables.

```
$ export AWS_PROFILE=<profile_name>
$ export KOPS_STATE_STORE=s3://<kops_cluster_statefile>
```

Step 4:

To run this, you need to execute:

```bash
$ Terraform init
$ Terraform plan
$ Terraform apply
```
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster_snapshots | Name of cluster to retrieve snapshots for | string | - | yes |
| cluster_restore | Name of cluster restoring to | string | - | yes |

Example cluster name: cloud-platform-testcluster.kubernetescluster.io


Step 5:

Once all 6 ebs volumes have been restored, reboot each of the master nodes - one at a time. You might see some of the new volumes already attached the nodes before reboot, this is expected behaviour. 

### Outputs

| Name | Description | 
|------|-------------|
| snapshot_id | Snapshot ID used to create each EBS volume  |

Step 6: 

Run `kops validate cluster` and 'kubectl get nodes'

It will take a number of minutes before you get any output from the above commands. It will take up to an additional 10 minutes before the cluster settles and most of the errors resolve. 

A this point, a full cluster health check is required to make sure all pods, services, deployments and ingresses and functioning as expected. 

**Note - There is no remote state file for etcd_ebs.tf**