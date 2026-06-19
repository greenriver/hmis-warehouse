#!/usr/bin/env ruby
###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../config/deploy/docker/lib/aws_sdk_helpers'

puts AwsSdkHelpers::Helpers.superset_env_for_warehouse
