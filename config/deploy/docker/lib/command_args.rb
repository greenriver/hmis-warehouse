# frozen_string_literal: true
require 'yaml'

class CommandArgs
  attr_accessor :deployments

  def initialize
    path = Pathname.new(__FILE__).join('..', '..', 'assets', 'secret.deploy.values.yml')
    config = YAML.load_file(path)
    defaults = config['_global_defaults'] || {}
    config.each_key do |key|
      config.delete(key) if key.match?(/^_/)
    end

    # Filter to just cas or warehouse
    app_file = Pathname.new(__FILE__).join('..', '..', '..', '..', '..', '.ecs-app-key')
    app = File.read(app_file).chomp
    config = config[app]

    raise "Set first param as group of environments to deploy/build: #{config.keys}" unless ARGV[0]

    self.deployments = config[ARGV[0]]

    raise "Set a valid group: #{ARGV[0]} must be in #{config.keys.join(', ')}" if deployments.nil?

    # Merge in defaults
    deployments.each_index do |i|
      deployments[i] = defaults.merge(deployments[i])
    end
  end

  def self.cluster
    ENV.fetch('AWS_CLUSTER') { ENV.fetch('AWS_PROFILE') { ENV.fetch('AWS_VAULT') } }
  end

  def cluster
    CommandArgs.cluster
  end
end
