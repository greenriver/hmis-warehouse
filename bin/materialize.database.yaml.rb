require 'erb'
require 'yaml'

template = ERB.new(File.read('config/database.yml'))
result = YAML.load(template.result(binding))
File.write('config/database.yml', result.to_yaml)

# puts result.to_yaml
