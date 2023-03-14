# frozen_string_literal: true

require 'yaml'
require 'dotenv'

class CommandArgs
  attr_accessor :deployments

  def initialize
    Dotenv.load('.env', '.env.local')

    path = Pathname.new(__FILE__).join('..', '..', 'assets', 'secret.deploy.values.yml')

    if File.exist?(path)
      local_config = YAML.load_file(path)
      local_config = nil if local_config.empty?
    else
      local_config = nil
    end

    remote_config_text = AwsSdkHelpers::Helpers.get_secret(ENV['SECRETS_YML_SECRET_ARN'])
    remote_config = YAML.safe_load(remote_config_text, permitted_classes: [Symbol], aliases: true)

    if !local_config.nil? && local_config != remote_config
      puts 'Local secrets.yml differs from remote config, would you like to pull down the remote version? This will overwrite your local file. [y/N]'
      unsure = $stdin.readline
      if unsure.chomp.downcase.match?(/y(es)?/)
        File.write(path, remote_config_text)
        config = remote_config
      else
        tmppath = "/tmp/remote-secrets-#{Time.now.to_i}.yml"
        File.write(tmppath, remote_config_text)
        puts "Okay. Remote config saved to #{tmppath} for your convenience. (Local is at #{path})"
        pp `diff #{path} #{tmppath}`
        puts 'continue anyway? [y/N]'
        unsure = $stdin.readline
        exit unless unsure.chomp.downcase.match?(/y(es)?/)
        config = local_config
        puts "[WARN] ❗ Using local config: #{path}"
      end
    elsif remote_config.nil?
      config = local_config
      puts "[WARN] ❗ Remote secrets.yml not found, using local: #{path}"
    else
      config = remote_config
    end

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
    ENV.fetch('CLUSTER_NAME', 'openpath')
  end

  def cluster
    CommandArgs.cluster
  end
end
