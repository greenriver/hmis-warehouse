#!/usr/bin/env ruby

# awscli adds too much weight
# api doesn't have s3 sync
# So, this script exists

require 'aws-sdk-s3'

define_method(:client) { Aws::S3::Client.new }

begin
  bucket = ENV.fetch('ASSETS_BUCKET_NAME')
  prefix = ENV.fetch('ASSETS_PREFIX') || 'default'

  resp = client.list_objects(
    {
      bucket: bucket,
      prefix: prefix,
    },
  )
  # resp = client.list_objects({ bucket: bucket, prefix: '', })

  puts 'Result is truncated. Too many keys. Continuing with what we can get' if resp.is_truncated

  keys = resp.to_h[:contents]&.map { |r| r[:key] }

  if keys.nil?
    puts "No assets found. exiting. is #{prefix} the correct prefix? Is #{bucket} the correct bucket?"
    exit
  end

  keys.each do |key|
    target = if prefix == ''
      key.sub(/#{prefix}/, './')
    else
      key.sub(/#{prefix}/, '.')
    end
    puts "#{key} -> #{File.expand_path(target)}"

    if target.end_with?('/')
      FileUtils.mkdir_p(target)
      next
    else
      i = target.rindex('/')
      FileUtils.mkdir_p(target[0..i])
    end

    if File.exist?(target) && ENV['UPDATE_ONLY'] == 'true'
      # puts "Skipping #{target} which already exists locally"
      next
    end

    resp = client.get_object(
      {
        bucket: bucket,
        key: key,
        response_target: target,
      },
    )
  end
rescue Aws::S3::Errors::NoSuchBucket
  abort "[#{__FILE__}] Cannot find the bucket: #{bucket}"
rescue Aws::S3::Errors::AccessDenied
  abort "[#{__FILE__}] Access denied to s3://#{bucket}/#{prefix}"
rescue Aws::Errors::MissingRegionError
  abort "[#{__FILE__}] specify a region to sync!"
rescue KeyError => e
  abort "[#{__FILE__}] #{e.message}: Cannot sync"
rescue StandardError => e
  abort "[#{__FILE__}] #{e.message}"
end
