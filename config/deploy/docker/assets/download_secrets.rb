#!/usr/bin/env ruby

begin
  require 'aws-sdk-secretsmanager'

  define_method(:client) { Aws::SecretsManager::Client.new }

  resp = client.get_secret_value(
    secret_id: ENV.fetch('SECRET_ARN')
  )

  puts resp.to_h[:secret_string]
rescue Aws::Errors::MissingCredentialsError
  STDERR.puts "Need credentials to sync secrets (or run on a server/container with a role)"
  puts "ERROR=secretsyncfailed"
end
