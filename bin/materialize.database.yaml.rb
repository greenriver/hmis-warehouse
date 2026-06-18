#!/usr/bin/env ruby
###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'erb'
require 'yaml'
require 'dotenv'

Dotenv.load('.env', '.env.local')
yml = File.read('config/database.yml')
# puts yml.inspect
template = ERB.new(yml)
# puts template.to_s
result = YAML.load(template.result(binding), aliases: true)
File.write('config/database.yml', result.to_yaml)

# puts result.to_yaml
