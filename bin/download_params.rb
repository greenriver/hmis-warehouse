#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/deploy/docker/lib/aws_sdk_helpers'

puts AwsSdkHelpers::Helpers.superset_env_for_warehouse
