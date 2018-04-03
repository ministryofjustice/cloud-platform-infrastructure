#!/usr/bin/env python
import boto3
import re
import json

with open('config.json', 'r') as f:
    config = json.loads(f.read() or '{}')


if not config.get('domain_name'):
    print("""ERROR: Fabric domain name not set!

        Set config.json['domain_name'] to a valid domain name in Route53""")

    exit(1)

bucket_name = "{0}-state".format(re.sub("[\W\d]+", "-", config.get('domain_name').lower().strip()))

s3 = boto3.client('s3')
bucket = s3.create_bucket(Bucket=bucket_name, ACL='private',
                          CreateBucketConfiguration=dict(LocationConstraint=config["fabric_region"]))
s3.put_bucket_versioning(
    Bucket=bucket_name,
    VersioningConfiguration={
        'Status': 'Enabled'
    }
)

print("Bucket: {}".format(bucket_name))
