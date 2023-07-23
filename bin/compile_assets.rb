#!/usr/bin/env ruby

require_relative '../config/deploy/docker/lib/command_args'
require_relative '../config/deploy/docker/lib/asset_compiler'

require 'dotenv'

Dotenv.load('.env', '.env.local')

args = CommandArgs.new

total = args.deployments.count
args.deployments.each_with_index do |deployment, index|
  compiling_for = ENV.fetch('DEPLOY_PROTECT_SECRETS', false) ? "#{deployment[:target_group_name][0]}*****": deployment[:target_group_name]
  puts "Compiling for #{compiling_for} (#{index}/#{total})..."
  target_group_name = deployment[:target_group_name].gsub(/[^0-9A-Za-z\_\-]/, '') # Sanitize for cli.
  secret_arn = deployment[:secrets_arn].gsub(/[^0-9A-Za-z\_\-\:\/]/, '') # Sanitize for cli.
  AssetCompiler.new(target_group_name: target_group_name, secret_arn: secret_arn).run!
end
