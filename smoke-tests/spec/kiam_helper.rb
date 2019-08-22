# TODO: convert this helper to an object, because it's sort of stateful

ASSUME_ROLE_POLICY_DOCUMENT = {
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
}

def try_to_assume_role(args)
  namespace = args.fetch(:namespace)
  pod = args.fetch(:pod)
  role_arn = args.fetch(:role_arn)

  cmd = %[kubectl exec -n #{namespace} #{pod} -- aws sts assume-role --role-arn "#{role_arn}" --role-session-name dummy]
  `#{cmd} 2>&1`
end

def fetch_or_create_role(args)
  role_name = args.fetch(:role_name)
  kubernetes_cluster = args.fetch(:kubernetes_cluster)
  account_id = args.fetch(:account_id)
  aws_region = args.fetch(:aws_region)

  client = Aws::IAM::Client.new(region: aws_region)

  role = Aws::IAM::Role.new(client: client, name: role_name)

  # TODO: use client.list_roles here
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/IAM/Client.html#get_role-instance_method

  begin
    role.load
  rescue Aws::IAM::Errors::NoSuchEntity
    role = create_role(client, role_name, kubernetes_cluster, account_id, aws_region)
  end

  assume_role_policy = fetch_or_create_policy(
    client,
    policy_document: ASSUME_ROLE_POLICY_DOCUMENT.to_json,
    policy_name: "test-kiam-polcy"
  )
  arn = assume_role_policy.arn

  unless role.attached_policies.map(&:arn).include?(arn)
    role.attach_policy(policy_arn: arn)
  end

  role
end

def fetch_or_create_policy(client, args)
  policy_name = args.fetch(:policy_name)

  begin
    resp = client.create_policy(
      policy_document: args.fetch(:policy_document),
      policy_name: policy_name
    )
    arn = resp.policy.arn
  rescue Aws::IAM::Errors::EntityAlreadyExists
    # TODO: do this first, so we don't do control flow via exception
    p = client.list_policies.policies.find {|p| p.policy_name == args.fetch(:policy_name) }
    raise("Unable to find or create policy #{policy_name}") if p.nil?
    arn = p.arn
  end

  Aws::IAM::Policy.new(client: client, arn: arn)
end

# TODO: too many positional parameters
def create_role(client, role_name, kubernetes_cluster, account_id, aws_region)
  iam = Aws::IAM::Resource.new(client: client)

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
