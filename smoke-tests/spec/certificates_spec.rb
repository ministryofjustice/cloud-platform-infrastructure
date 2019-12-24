require "spec_helper"

describe "certificates" do

  specify "expected Certificate" do
    names = get_certificates.map { |set| set.dig("metadata", "name") }.sort

    expected = [
        "default",
        "mourad"
    ]
    expect(names).to include(*expected)
  end
end
