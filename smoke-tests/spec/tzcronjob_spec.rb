require "spec_helper"

describe "tzcronjobs" do
  let(:namespace) { "integrationtest-tzcronjob-#{readable_timestamp}" }
  let(:job_name) { "tzcronjob-integrationtest" }

  before do
    create_namespace(namespace)
  end

  after do
    delete_namespace(namespace)
  end

  it "job is scheduled" do
    # Create tzconrjob from template
    apply_template_file(
      namespace: namespace,
      file: "spec/fixtures/tzcronjob.yaml.erb",
      binding: binding
    )

    sleep 60

    # Check whether the tzcronjob scheduled a pod
    pod = get_pod_matching_name(namespace, job_name)

    expect(pod).not_to be nil
  end
end
