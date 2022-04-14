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
  AssetCompiler.new(**deployment).run!
end
