#!/usr/bin/env ruby
require_relative '../lib/aws_sdk_helpers'

puts AwsSdkHelpers::Helpers.get_secret(ENV.fetch('SECRET_ARN'))
