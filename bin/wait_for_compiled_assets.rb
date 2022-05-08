#!/usr/bin/env ruby
require_relative '../config/deploy/docker/lib/asset_compiler.rb'

target_group_name = ENV.fetch('TARGET_GROUP_NAME', false)
checksum = ENV.fetch('ASSET_CHECKSUM', false)

raise 'Waiting for compiled assets error: TARGET_GROUP_NAME not defined' unless target_group_name
raise 'Waiting for compiled assets error: ASSET_CHECKSUM not defined' unless checksum

compiled_assets_s3_path = AssetCompiler.compiled_assets_s3_path(target_group_name, checksum)
while `aws s3 ls #{compiled_assets_s3_path.shellescape}`.strip.empty?
  puts "[INFO] Assets for hash [#{checksum}] not compiled yet, waiting 60 seconds..."
  sleep 60
end
puts "[INFO] Assets for hash [#{checksum}] are compiled, proceeding..."
