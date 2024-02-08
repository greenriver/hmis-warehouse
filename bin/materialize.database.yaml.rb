#!/usr/bin/env ruby
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
