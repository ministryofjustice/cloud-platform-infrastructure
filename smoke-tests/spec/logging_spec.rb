require "spec_helper"

# Use the cluster: 'live-1' tag to identify tests which can only run against the live-1 cluster
# (in this case, because that's the only place where elasticsearch is set up with these values)
describe "Log collection", "live-1": true do
  let(:namespace) { "smoketest-logging-#{readable_timestamp}" }

  ELASTIC_SEARCH = "https://search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"

  before do
    create_namespace(namespace)
  end

  after do
    delete_namespace(namespace)
  end

  it "logs to elasticsearch" do
    # this job just outputs 'hello world' to stdout
    create_job(namespace, "spec/fixtures/helloworld-job.yaml.erb", job_name: "smoketest-helloworld-job")

    # It takes time for the 'helloworld' job output to be shipped to elasticsearch, and there
    # is no easy way to figure out when this has/hasn't happened. This sleep seems to work
    # consistently, but it's possible it may break unexpectedly, at some point.

    sleep 120 # TODO: this is an experimental change (from 60), to see if a longer sleep fixes
    #       intermittent pipeline failures

    date = Date.today.strftime("%Y.%m.%d")
    search_url = "#{ELASTIC_SEARCH}/logstash-#{date}/_search"

    # this job queries elasticsearch, looking for all log data for our namespace, today
    create_job(namespace, "spec/fixtures/logging-job.yaml.erb", {
      job_name: "smoketest-logging-job",
      search_url: search_url,
    })

    pod = get_pod_matching_name(namespace, "smoketest-logging-job")
    pod_name = pod.dig("metadata", "name")
    json = get_pod_logs(namespace, pod_name) # results from the elasticsearch query
    hash = JSON.parse(json)
    total_hits = hash.fetch("hits").fetch("total")
    expect(total_hits).to be > 0 # i.e. there are some log events for our namespace
  end
end
