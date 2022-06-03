#!/usr/bin/env ruby
require_relative '../config/deploy/docker/lib/aws_sdk_helpers'

githash = ENV.fetch('GITHASH')
variant = ENV.fetch('VARIANT', 'web')

raise "This githash (#{githash}) is being used in a deployed application and cannot be rebuilt" if AwsSdkHelpers::Helpers.githash_is_latest(githash, variant)
