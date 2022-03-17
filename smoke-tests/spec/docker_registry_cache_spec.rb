require "spec_helper"

xdescribe "docker-registry-cache", kops: true do
  let(:namespace) { "docker-registry-cache" }

  context "pod" do
    let(:pods) { get_running_pods(namespace) }
    let(:pod) { pods.first }

    specify "one pod running", speed: "fast" do
      expect(pods.length).to eq(1)
    end

    specify "running the cache image", speed: "fast" do
      image = pod.dig("spec", "containers").first.fetch("image")
      expect(image).to match("ministryofjustice.docker-registry-cache")
    end

    # Docker on the worker nodes should hit the docker-registry
    # instance in the cluster whenever a container is launched.
    # To test this, we check to see if any log output is generated
    # when a container is launched. This is a bit indirect, but
    # it works.
    it "logs output when a container is launched" do
      pod_name = pod.dig("metadata", "name")

      before_lines = get_pod_logs(namespace, pod_name).split("\n")
      execute("kubectl run --generator=run-pod/v1 output-date --image alpine date > /dev/null")

      sleep 60

      after_lines = get_pod_logs(namespace, pod_name).split("\n")
      execute("kubectl delete pod output-date > /dev/null")

      # Test that there were more lines in the log after the
      # container was launched.
      expect((after_lines - before_lines).count).to be > 0
    end
  end

  context "ingress", speed: "fast" do
    let(:ingresses) { get_ingresses(namespace) }
    let(:ingress) { ingresses.first }

    specify "one ingress" do
      expect(ingresses.length).to eq(1)
    end

    specify "ingress hostname" do
      host = ingress.dig("spec", "rules").first.dig("host")
      expect(host).to eq("docker-registry-cache.apps.#{current_cluster}")
    end

    # This merely tests that the annotation is in place, not that it is doing
    # what it's supposed to do (return a 403 to any requests from outside the
    # cluster).
    # We can test the allow list by executing this:
    #
    #     curl -I https://docker-registry-cache.apps.david-test7.cloud-platform.service.justice.gov.uk/v2/
    #
    # From inside the cluster, you get a 200, from outside a 403. But, when
    # running in the pipeline, these tests run from inside the cluster, so
    # we can't have a test for this.
    specify "allow list annotation" do
      allow_list = ingress.dig("metadata", "annotations", "nginx.ingress.kubernetes.io/whitelist-source-range")
      cidr_ranges = allow_list.split(",")
      expect(cidr_ranges.length).to eq(3)
      cidr_ranges.each do |cidr|
        expect(cidr).to match(%r{^\d+\.\d+\.\d+\.\d+/32$}) # e.g. 35.177.183.191/32
      end
    end
  end
end
