#!/usr/bin/env ruby

require_relative '../config/deploy/docker/lib/command_args'
require_relative '../config/deploy/docker/lib/asset_compiler'

require 'dotenv'

Dotenv.load('.env', '.env.local')

args = CommandArgs.new

args.deployments.each do |deployment|
  puts "Compiling for #{deployment[:target_group_name]}..." unless ENV.fetch('DEPLOY_PROTECT_SECRETS', false)
  AssetCompiler.new(**deployment).run!
end
