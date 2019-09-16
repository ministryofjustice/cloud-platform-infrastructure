class KiamRole
  attr_reader :kubernetes_cluster, :account_id, :aws_region, :role_name

  ASSUME_ROLE_POLICY_DOCUMENT = {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "sts:AssumeRole",
        ],
        Resource: [
          "*",
        ],
      },
    ],
  }

  def initialize(args)
    @kubernetes_cluster = args.fetch(:kubernetes_cluster)
    @account_id = args.fetch(:account_id)
    @aws_region = args.fetch(:aws_region)
    @role_name = args.fetch(:role_name)
  end

  def fetch_or_create_role
    role = Aws::IAM::Role.new(client: client, name: role_name)
    if list_roles(client).find { |r| r.role_name == role_name }
      role.load
      ensure_cluster_nodes_are_trusted(role)
    else
      role = create_role
    end

    assume_role_policy = fetch_or_create_policy(
      policy_document: ASSUME_ROLE_POLICY_DOCUMENT.to_json,
      policy_name: "integration-test-kiam-policy"
    )
    arn = assume_role_policy.arn

    unless role.attached_policies.map(&:arn).include?(arn)
      role.attach_policy(policy_arn: arn)
    end

    role
  end

  private

  def list_roles(client)
    rtn = []
    is_truncated = true
    marker = nil

    while is_truncated
      roles = client.list_roles(marker: marker)
      rtn += roles.roles
      is_truncated = roles.is_truncated
      marker = roles.marker
    end

    rtn
  end

  # If the role was created during a test run for a different cluster, the current
  # cluster's nodes will not be included as principals in the role's trust
  # relationships.
  # This method finds the principals and adds this cluster's nodes, if they're not
  # already listed.
  def ensure_cluster_nodes_are_trusted(role)
    # NB: role.load must have been called before this method is called
    json = CGI.unescape(role.assume_role_policy_document)
    policy = JSON.parse(json)
    principals = Array(policy.fetch("Statement").first.dig("Principal", "AWS"))
    unless principals.include?(cluster_nodes_policy_principal)
      principals << cluster_nodes_policy_principal
      policy.fetch("Statement").first.fetch("Principal")["AWS"] = principals
      client.update_assume_role_policy(policy_document: policy.to_json, role_name: role_name)
    end
  end

  def create_role
    iam = Aws::IAM::Resource.new(client: client)

    node_assume_role_policy_doc = {
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: {
            AWS: [cluster_nodes_policy_principal.to_s],
          },
          Action: "sts:AssumeRole",
        },
      ],
    }

    role = iam.create_role(
      role_name: role_name,
      assume_role_policy_document: node_assume_role_policy_doc.to_json,
    )

    client.wait_until(:role_exists, role_name: role_name)

    role
  end

  def cluster_nodes_policy_principal
    "arn:aws:iam::#{account_id}:role/nodes.#{kubernetes_cluster}"
  end

  def fetch_or_create_policy(args)
    policy_name = args.fetch(:policy_name)

    if policy = client.list_policies.policies.find { |p| p.policy_name == args.fetch(:policy_name) }
      arn = policy.arn
    else
      resp = client.create_policy(
        policy_document: args.fetch(:policy_document),
        policy_name: policy_name
      )
      arn = resp.policy.arn
    end

    Aws::IAM::Policy.new(client: client, arn: arn)
  end

  def client
    @client ||= Aws::IAM::Client.new(region: aws_region)
  end
end

def fetch_or_create_role(args)
  KiamRole.new(args).fetch_or_create_role
end

# Run a command, on the pod in the namespace, to try and assume the role, and capture the output from it.
def try_to_assume_role(args)
  namespace = args.fetch(:namespace)
  role_arn = args.fetch(:role_arn)
  pod = args.fetch(:pod)

  cmd = %(kubectl exec -n #{namespace} #{pod} -- aws sts assume-role --role-arn "#{role_arn}" --role-session-name dummy)
  `#{cmd} 2>&1`
end

# Deploy a container into a namespace. The container just runs 'sleep 86400'.
# We will run commands on the container using kubectl exec, and capture the output
def create_deployment(args)
  namespace = args.fetch(:namespace)
  pod_annotations = args.fetch(:pod_annotations)

  json = <<~EOF
    {
      "apiVersion": "apps/v1",
      "kind": "Deployment",
      "metadata": { "name": "integration-test-kiam-deployment" },
      "spec": {
        "selector": { "matchLabels": { "app": "not-needed" } },
        "template": {
          "metadata": {
            "annotations": #{pod_annotations.to_json},
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

  cmd = %(echo '#{jsn}' | kubectl -n #{namespace} apply -f -)

  `#{cmd}`

  pods = []

  60.times do
    pods = get_running_pods(namespace)
    break if pods.count > 0
    sleep 1
  end

  pods.first.dig("metadata", "name")
end
