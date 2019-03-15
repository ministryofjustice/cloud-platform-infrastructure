#!/bin/sh

set -o errexit

aws ec2 --region "${aws_region}" associate-address --instance-id "$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" --allocation-id "${eip_id}"

systemctl daemon-reload
systemctl enable authorized-keys-manager.service
systemctl start authorized-keys-manager.service
systemctl restart ssh.service
