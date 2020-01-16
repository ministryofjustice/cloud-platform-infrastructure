#!/usr/bin/env ruby

# Dump all route53 records as a CSV file
#
# Pre-requisites
#
# * AWS credentials, with the appropriate AWS_PROFILE env. var. value
# * The aws-cli tool installed
#
# NB: Hosted zones which contain no records will not be included in
# the output from this script.

require "json"
require "csv"
require "pry-byebug"

DnsRecord = Struct.new(
  :hosted_zone_name,
  :hosted_zone_id,
  :record_type,
  :record_name,
  :ttl,
  :value,
) do
  def to_csv
    CSV.generate_line([
      hosted_zone_name,
      hosted_zone_id,
      record_type,
      record_name,
      ttl,
      value,
    ], force_quotes: true)
  end
end

############################################################

puts CSV.generate_line([
      "Zone name",
      "Zone id",
      "Type",
      "Name",
      "TTL",
      "Value",
], force_quotes: true)

hosted_zones = JSON.parse(`aws route53 list-hosted-zones`).fetch("HostedZones")

hosted_zones.each do |hz|
  hosted_zone_name= hz.fetch("Name")
  hosted_zone_id= hz.fetch("Id")

  record_sets = JSON.parse(`aws route53 list-resource-record-sets --hosted-zone-id #{hosted_zone_id}`).fetch("ResourceRecordSets")

  record_sets.each do |rs|
    resource_records = rs["ResourceRecords"]

    if resource_records != nil
      resource_records.each do |record|
        dns_rec = DnsRecord.new

        dns_rec.hosted_zone_name = hosted_zone_name
        dns_rec.hosted_zone_id = hosted_zone_id
        dns_rec.record_type = rs.fetch("Type")
        dns_rec.record_name = rs.fetch("Name")
        dns_rec.ttl = rs.fetch("TTL")
        dns_rec.value = record.fetch("Value")

        puts dns_rec.to_csv
      end
    end
  end
rescue Exception => e
  binding.pry
  1
end
