
###########
# For some reason I am not sure this didn't work out of the box in EKS. 
# I need to invest more time debugging it, I know kube2iam does so I deployed it
###########

# resource "tls_private_key" "ca" {
#   algorithm   = "ECDSA"
#   ecdsa_curve = "P384"
# }

# resource "tls_self_signed_cert" "ca" {
#   key_algorithm     = tls_private_key.ca.algorithm
#   private_key_pem   = tls_private_key.ca.private_key_pem
#   is_ca_certificate = true

#   validity_period_hours = 87600 // 10 years
#   early_renewal_hours   = 720   // 1 month

#   subject {
#     common_name = "Kiam CA"
#   }

#   allowed_uses = [
#     "cert_signing",
#     "crl_signing",
#   ]
# }

# resource "tls_private_key" "agent" {
#   algorithm   = "ECDSA"
#   ecdsa_curve = "P384"
# }

# resource "tls_cert_request" "agent" {
#   key_algorithm   = tls_private_key.agent.algorithm
#   private_key_pem = tls_private_key.agent.private_key_pem

#   subject {
#     common_name = "Kiam Agent"
#   }
# }

# resource "tls_locally_signed_cert" "agent" {
#   cert_request_pem   = tls_cert_request.agent.cert_request_pem
#   ca_key_algorithm   = tls_private_key.ca.algorithm
#   ca_private_key_pem = tls_private_key.ca.private_key_pem
#   ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

#   validity_period_hours = 8760 // 1 year
#   early_renewal_hours   = 720  // 1 month

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "client_auth",
#     "server_auth",
#   ]
# }

# resource "tls_private_key" "server" {
#   algorithm   = "ECDSA"
#   ecdsa_curve = "P384"
# }

# resource "tls_cert_request" "server" {
#   key_algorithm   = tls_private_key.server.algorithm
#   private_key_pem = tls_private_key.server.private_key_pem

#   subject {
#     common_name = "Kiam Server"
#   }

#   dns_names = [
#     "kiam-server",
#   ]

#   ip_addresses = [
#     "127.0.0.1",
#   ]
# }

# resource "tls_locally_signed_cert" "server" {
#   cert_request_pem   = tls_cert_request.server.cert_request_pem
#   ca_key_algorithm   = tls_private_key.ca.algorithm
#   ca_private_key_pem = tls_private_key.ca.private_key_pem
#   ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

#   validity_period_hours = 8760 // 1 year
#   early_renewal_hours   = 720  // 1 month

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "client_auth",
#     "server_auth",
#   ]
# }

# resource "null_resource" "kube_system_kiam_annotation" {
#   provisioner "local-exec" {
#     command = "kubectl annotate --overwrite namespace kube-system 'iam.amazonaws.com/permitted=.*'"
#   }
# }

# data "helm_repository" "uswitch" {
#   name = "uswitch"
#   url  = "https://uswitch.github.io/kiam-helm-charts/charts/"
# }

# resource "helm_release" "kiam" {
#   name          = "kiam"
#   chart         = "uswitch/kiam"
#   namespace     = "kiam"
#   recreate_pods = "true"
#   #version       = "2.4.0"
#   version       = "5.1.0"
#   repository    = data.helm_repository.uswitch.metadata.0.name


#   values = [templatefile("${path.module}/templates/kiam.yaml.tpl", {
#     kiam_version = "v3.4"
#     ca           = base64encode(tls_self_signed_cert.ca.cert_pem)
#     agent_cert   = base64encode(tls_locally_signed_cert.agent.cert_pem)
#     agent_key    = base64encode(tls_private_key.agent.private_key_pem)
#     server_cert  = base64encode(tls_locally_signed_cert.server.cert_pem)
#     server_key   = base64encode(tls_private_key.server.private_key_pem)
#   })]


#   depends_on = [
#     null_resource.deploy,
#   ]
# }


# ## THis is a test role
# data "aws_iam_policy_document" "testRole_assume" {

#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "AWS"
#       identifiers = [data.aws_iam_role.nodes.arn]
#     }
#   }

#   statement {
#     actions = [
#       "sts:AssumeRole",
#     ]

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }

#     effect = "Allow"
#   }
# }

# resource "aws_iam_role" "testRole" {
#   name               = "test.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
#   assume_role_policy = data.aws_iam_policy_document.testRole_assume.json
# }

# data "aws_iam_policy_document" "testRole" {
#   statement {
#     actions = [
#             "s3:CreateBucket", 
#             "s3:ListAllMyBuckets", 
#             "s3:GetBucketLocation"  
#     ]

#     resources = ["*"]
#   }
# }

# resource "aws_iam_role_policy" "testRole" {
#   name   = "test-s3"
#   role   = aws_iam_role.testRole.id
#   policy = data.aws_iam_policy_document.testRole.json
# }