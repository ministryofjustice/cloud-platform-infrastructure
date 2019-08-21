def try_to_assume_role(args)
  namespace = args.fetch(:namespace)
  pod = args.fetch(:pod)
  role_arn = args.fetch(:role_arn)

  cmd = %[kubectl exec -n #{namespace} #{pod} -- aws sts assume-role --role-arn "#{role_arn}" --role-session-name dummy]
  `#{cmd} 2>&1`
end

def create_role_if_not_exists(args)
  role_name = args.fetch(:role_name)
  kubernetes_cluster = args.fetch(:kubernetes_cluster)
  account_id = args.fetch(:account_id)
  aws_region = args.fetch(:aws_region)

  (role = role_exists?(role_name, aws_region)) ? role : create_role(role_name, kubernetes_cluster, account_id, aws_region)
end

def role_exists?(role_name, aws_region)
  client = Aws::IAM::Client.new(region: aws_region)

  begin
    client.get_role(role_name: role_name)
  rescue Aws::IAM::Errors::NoSuchEntity
    false
  end
end

def create_policy_if_not_exists(client, args)
  client.create_policy(
    policy_document: args.fetch(:policy_document),
    policy_name: args.fetch(:policy_name)
  )
rescue Aws::IAM::Errors::EntityAlreadyExists
  binding.pry ; 1

  # TODO: find policy by name
  # client.list_policies.policies.find {|p| p.policy_name == args.fetch(:policy_name) }


end

# TODO: too many positional parameters
def create_role(role_name, kubernetes_cluster, account_id, aws_region)
  client = Aws::IAM::Client.new(region: aws_region)
  iam = Aws::IAM::Resource.new(client: client)

  assume_role_policy = create_policy_if_not_exists(client,
    policy_document: {
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "sts:AssumeRole"
          ],
          Resource: [
            "*"
          ]
        }
      ]
    }.to_json,
    policy_name: "test-kiam-polcy"
  )

  node_assume_role_policy_doc = {
    Version:"2012-10-17",
    Statement:[
      {
        Effect:"Allow",
        Principal:{
          AWS: "arn:aws:iam::#{account_id}:role/nodes.#{kubernetes_cluster}"
        },
        Action:"sts:AssumeRole"
      }
    ]
  }

  role = iam.create_role(
    role_name: role_name,
    assume_role_policy_document: node_assume_role_policy_doc.to_json,
  )

  client.wait_until(:role_exists, role_name: role_name)

  # TODO: Needs to be created at runtime
  # role.attach_policy(policy_arn: 'arn:aws:iam::754256621582:policy/test-kiam-policy')
  role.attach_policy(policy_arn: assume_role_policy.dig(:policy, :arn))

  role
end

def create_deployment(namespace)
  json = <<~EOF
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": { "name": "test-kiam-deployment" },
    "spec": {
      "selector": { "matchLabels": { "app": "not-needed" } },
      "template": {
        "metadata": {
          "annotations": { "iam.amazonaws.com/role": "test-kiam-iam-role" },
          "labels": { "app": "not-needed" }
        },
        "spec": {
          "securityContext": {
            "runAsUser": 1000,
            "runAsGroup": 3000
          },
          "containers": [
            {
              "name": "tools-image",
              "image": "#{TOOLS_IMAGE}",
              "command": [ "sleep", "86400" ]
            }
          ]
        }
      }
    }
  }
  EOF

  # collapse the json onto a single line
  jsn = JSON.parse(json).to_json

  cmd = %[echo '#{jsn}' | kubectl -n #{namespace} apply -f -]

  `#{cmd}`

  pod = ""

  60.times do
    pod = get_running_pod_name(namespace, 1)
    break if pod.length > 0
    sleep 1
  end

  pod
end

