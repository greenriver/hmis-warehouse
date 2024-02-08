require 'date'
require 'byebug'
require 'English'
require_relative 'roll_out'
require_relative 'aws_sdk_helpers'
require_relative 'asset_compiler'

class Deployer
  include AwsSdkHelpers::Helpers

  attr_accessor :repo_name
  attr_accessor :registry_id

  ROOT_PATH   = File.realpath(File.join(__dir__, '..', '..', '..', '..'))

  ASSETS_PATH = File.join(ROOT_PATH, 'config', 'deploy', 'docker', 'assets')
  TEST_HOST   = 'deploy.warehouse.dev.test'.freeze
  TEST_PORT   = 9999
  WAIT_TIME   = 2

  attr_accessor :version
  attr_accessor :image_tag
  attr_accessor :image_tag_latest

  # The AWS identifier for the payload of secret environment variables
  attr_accessor :secrets_arn

  # We have one load balancer, and a target group for each environment
  attr_accessor :target_group_name

  attr_accessor :execution_role
  attr_accessor :task_role

  # web, delayed jobs, and cron are all variants of the base image. There could
  # be more possibly in the future
  attr_accessor :variant

  attr_accessor :dj_options

  attr_accessor :web_options

  # The fully-qualified domain name of the application
  # We use this so we can get data from the app about the deployment state
  attr_accessor :fqdn

  attr_accessor :cluster

  attr_accessor :service_registry_arns

  attr_accessor :args

  def initialize(args)
    self.service_registry_arns    = args.fetch(:service_registry_arns)
    self.cluster                  = _cluster_name
    self.target_group_name        = args.fetch(:target_group_name)
    self.secrets_arn              = args.fetch(:secrets_arn)
    self.execution_role           = args.fetch(:execution_role)
    self.task_role                = args.fetch(:task_role)
    self.dj_options               = args.fetch(:dj_options, [])
    self.fqdn                     = args.fetch(:fqdn)
    self.web_options              = args.fetch(:web_options)
    self.registry_id              = args.fetch(:registry_id)
    self.repo_name                = args.fetch(:repo_name)
    self.variant                  = 'web'
    self.version                  = `git rev-parse --short=7 HEAD`.chomp
    self.args                     = OpenStruct.new(args)

    Dir.chdir(_root)
  end

  def only_web!
    _initial_steps
    roll_out.only_web!
  end

  def check_ram!
    _set_revision!
    _set_image_tag!
    roll_out.check_ram!
  end

  def run!
    _initial_steps

    roll_out.run!

    _add_latest_tag!
  end

  def run_migrations!
    _initial_steps

    roll_out.run_migrations!
  end

  def bootstrap_databases!
    _initial_steps

    print "Boostrapping databases for #{target_group_name}. Are you sure? (Y/N): "
    unsure = $stdin.readline
    if unsure.chomp.upcase != 'Y'
      puts 'Okay. Not running the task.'
      exit
    end

    roll_out.bootstrap_databases!
  end

  def self.check_that_you_pushed_to_remote!
    branch = `git rev-parse --abbrev-ref HEAD`.chomp
    remote = `git ls-remote origin | grep refs/heads/#{branch}$`.chomp
    our_commit = `git rev-parse #{branch}`.chomp

    raise '[FATAL] Push or pull your branch first!' unless remote.start_with?(our_commit)
  end

  private

  def _initial_steps
    # _ensure_clean_repo!
    _set_revision!
    _check_that_you_pushed_to_remote!
    _docker_login!
    _wait_for_image_ready
    _check_secrets!
  end

  def roll_out
    @roll_out ||=
      RollOut.new(
        dj_options: dj_options,
        image_base: _remote_tag_base,
        secrets_arn: secrets_arn,
        target_group_arn: _target_group_arn,
        target_group_name: target_group_name,
        execution_role: execution_role,
        fqdn: fqdn,
        task_role: task_role,
        web_options: web_options,
        capacity_providers: _capacity_providers,
        service_registry_arns: service_registry_arns,
        args: args,
      )
  end

  def _ensure_clean_repo!
    return unless `git status --porcelain` != ''

    puts '[FATAL] Aborting since git is not clean'
    exit 1
  end

  def _set_revision!
    `git rev-parse HEAD > #{_assets_path}/REVISION`
  end

  def _check_that_you_pushed_to_remote!
    self.class.check_that_you_pushed_to_remote!
  end

  def _check_compiled_assets!
    secrets_arn_ = secrets_arn.gsub(/[^0-9A-Za-z\_\-\:\/]/, '') # Sanitize for cli.
    target_group_name_ = target_group_name&.gsub(/[^0-9A-Za-z\_\-]/, '') # Sanitize for cli.
    checksum = `SECRET_ARN=#{secrets_arn_.shellescape} ASSETS_PREFIX=#{target_group_name_.shellescape} bin/asset_checksum`.split(' ')[-1]

    compiled_assets_s3_path = AssetCompiler.compiled_assets_s3_path(target_group_name_, checksum)
    while `aws s3 ls #{compiled_assets_s3_path.shellescape}`.strip.empty?
      puts "[INFO] Assets for hash [#{checksum}] not compiled yet, waiting 60 seconds..."
      sleep 60
    end
    puts "[INFO] Assets for hash [#{checksum}] are compiled, proceeding..."
  end

  def _docker_login!
    resp = ecr.get_authorization_token
    data = resp.to_h[:authorization_data].first
    user, pass = Base64.decode64(data[:authorization_token]).split(/:/)
    server = data[:proxy_endpoint]
    cmd = "docker login -u #{user} -p #{pass} #{server}"
    _run(cmd, alt_msg: 'docker login')
  end

  def _wait_for_image_ready
    _set_image_tag!

    while _revision_not_in_repo?
      puts "[INFO] Build did not finish yet for #{image_tag}. Trying again in #{WAIT_TIME} minutes."
      # puts "[DEBUG] These are the tags:"
      # puts _image_tags_in_repo.join(', ')

      sleep WAIT_TIME * 60
    end
  end

  def _add_latest_tag!
    _set_image_tag!

    puts "[INFO] Update latest tag for '#{image_tag}':"
    # if image_tag_latest.nil?
    #   puts '>> Skipping, no latest tag set (this is the pre-cache image).'
    #   return
    # end

    getparams = {
      repository_name: repo_name,
      image_ids: [
        { image_tag: image_tag },
        { image_tag: image_tag_latest },
      ],
    }
    images = ecr.batch_get_image(getparams).images

    if images.count == 2 && images[0].image_id.image_digest == images[1].image_id.image_digest
      puts ">> Latest tag '#{image_tag_latest}' is already even with tag '#{image_tag}'."
      return
    elsif images.count > 2
      raise 'More than two images found during latest-* check, something is wrong.'
    elsif images.count < 1
      raise "No images matching tag #{image_tag} found during latest-* check, something is wrong."
    end

    image = images.find { |i| i.image_id.image_tag == image_tag }
    manifest = image.image_manifest

    raise "No manifest matching tag #{image_tag} found during latest-* check, something is wrong." if manifest.nil?

    putparams = {
      repository_name: repo_name,
      image_tag: image_tag_latest,
      image_manifest: manifest,
    }
    response = ecr.put_image(putparams)
    logfile = File.join('tmp', "latest-tag-log--#{image_tag}--#{image_tag_latest}--#{Time.now.strftime('%m-%d--%H:%M:%S')}")
    File.write(logfile, response.to_h.inspect)
    puts ">> Latest tag '#{image_tag_latest}' is now even with '#{image_tag}'"
  end

  def _check_secrets!
    if secrets_arn.nil?
      puts 'Please specify a secrets arn in your secret.deploy.values.yml file'
      exit
    end

    secretsmanager.describe_secret(secret_id: secrets_arn)
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    puts "Cannot find #{secrets_arn}. Aborting"
    exit
  end

  def _ruby_version
    @_ruby_version ||= File.read('.ruby-version').chomp
  end

  def _pre_cache_version
    @_pre_cache_version ||= File.read('.pre-cache-version').chomp
  end

  def _set_image_tag!
    if ENV['IMAGE_TAG']
      self.image_tag = ENV['IMAGE_TAG']
      self.image_tag_latest = 'latest-' + ENV['IMAGE_TAG']
    else
      self.image_tag = "githash-#{version}"
      self.image_tag_latest = "latest-#{target_group_name}"
    end

    # puts "Setting image tag to #{image_tag}"
  end

  def debug?
    ENV['DEBUG'] == 'true'
  end

  def _image_tags_in_repo
    params = {
      registry_id: registry_id,
      repository_name: repo_name,
      max_results: 100,
      filter: {
        tag_status: 'TAGGED',
      },
    }

    ecr.list_images(params).flat_map do |set|
      set.image_ids.map(&:image_tag)
    end
  end

  def _revision_not_in_repo?
    _image_tags_in_repo.none? do |tag|
      tag == image_tag
    end
  end

  def _remote_tag
    "#{repo_url}:#{image_tag}"
  end

  def _remote_latest_tag
    "#{repo_url}:latest--#{variant}"
  end

  def _remote_tag_base
    _remote_tag.reverse.sub(/^(\w+--)?/, '').reverse
  end

  def _run(cmd, alt_msg: nil)
    command = cmd.gsub(/\n/, ' ').squeeze(' ')
    puts "Running #{alt_msg || command}"

    system(command)

    raise 'Aborting deployment due to command error' if $CHILD_STATUS.exitstatus != 0
  end

  def _dockerfile_path
    "#{_assets_path}/Dockerfile.#{repo_name}.#{variant}"
  end

  def _assets_path
    ASSETS_PATH
  end

  def _root
    ROOT_PATH
  end

  def repo_url
    "#{registry_id}.dkr.ecr.us-east-1.amazonaws.com/#{repo_name}".freeze
  end

  def _target_group_arn
    return @target_group_arn unless @target_group_arn.nil?

    results = elbv2.describe_target_groups

    @target_group_arn = results.target_groups.find do |tg|
      tg.target_group_name == target_group_name
    end.target_group_arn
  end
end
