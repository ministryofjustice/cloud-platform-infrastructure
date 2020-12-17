require "spec_helper"

describe "namespace", kops: true do
 
    namespaces = ['kube-system','cert-manager', 'velero', 'monitoring', 'logging']
    kiam_annotation = "iam.amazonaws.com/permitted"

    let(:namespace) { "integrationtest-kiam-#{random_string}-#{readable_timestamp}" }
    context "namespace has required annotations" do

        namespaces.each do |namespace|
            it ":kiam" do
                anno= get_namespace_annotations(namespace)
                result = anno.key?(kiam_annotation)
                expect(result).to be true
            end
        end

    end
end
