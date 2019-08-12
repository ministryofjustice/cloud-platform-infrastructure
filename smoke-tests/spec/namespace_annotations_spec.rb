require "spec_helper"

describe "namespaces" do

  # Monitoring is automatically set up for all namespaces which have specific
  # annotations. So, if any namespaces don't have any, it's a problem.
  specify "must have annotations" do
    # This finds namespaces which either don't have an annotations entry, or which
    # have one but it's empty. This might be overkill, but it doesn't add much
    # complexity to the test.
    unannotated_namespaces = all_namespaces.map {|ns| ns.fetch("metadata")}
      .map {|metadata| [metadata.fetch("name"), metadata.fetch("annotations", {}).keys.length] }
      .filter {|i| i[1] == 0 }
      .map {|i| i[0]}

    # These namespaces are allowed to not have annotations
    %w(default kube-public).map { |ns| unannotated_namespaces.delete(ns) }

    expect(unannotated_namespaces).to eq([])
  end

end
