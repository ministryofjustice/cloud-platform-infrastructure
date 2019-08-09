#!/usr/bin/env ruby

require "bundler/setup"
require "aws-sdk-iam"
require "aws-sdk-ec2"

#####################################################
# This script uses IAM role with permissions and uses 
# AssumeRole to create credentials dynamically in 'role_credentials'
######################################################
def main
    check_prerequisites

    role_arn = "arn:aws:iam::"+env('ACCOUNT_ID')+":role/"+env('ROLE_NAME')       
   
    begin
      role_credentials = Aws::AssumeRoleCredentials.new(
      role_arn: role_arn,
      role_session_name: "cluster_backup_checker_session"
      )
      
      if role_credentials
        puts "SUCCESS: Pod able to AssumeRole"
      end
    rescue
      puts "Aws::STS::Errors => Unable to AssumeRole for #{role_arn}"
    end
   
end


def check_prerequisites
    %w(
        ACCOUNT_ID
        ROLE_NAME
        AWS_REGION
        KUBERNETES_CLUSTER
    ).each do |var|
      env(var)
    end
end
  
def env(var)
    ENV.fetch(var)
end
  
main