require 'date'
require 'byebug'
require 'English'
require_relative 'roll_out'

# gem install aws_sdk --version=3.1.5
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-ecr'
require 'aws-sdk-secretsmanager'

class Deployer
  attr_accessor :repo_name
  attr_accessor :registry_id

  ROOT_PATH      = File.realpath(File.join(__dir__, '..',  '..', '..', '..'))

  ASSETS_PATH    = File.join(ROOT_PATH, 'config', 'deploy', 'docker', 'assets')
  AWS_PROFILE    = ENV.fetch('AWS_PROFILE')
  TEST_HOST      = 'deploy.warehouse.dev.test'
  TEST_PORT      = 9999
  WAIT_TIME      = 2

  attr_accessor :image_tag

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

  # github actions or other CI builds the image, so when true, don't try to
  # build locally and push (which can be slow).
  attr_accessor :assume_ci_build
  attr_accessor :push_allowed

  attr_accessor :force_build

  # The fully-qualified domain name of the application
  # We use this so we can get data from the app about the deployment state
  attr_accessor :fqdn

  def initialize(target_group_name:, assume_ci_build: true, secrets_arn:, execution_role:, task_role:, dj_options: nil, web_options:, registry_id:, repo_name:, fqdn:)
    self.target_group_name = target_group_name
    self.assume_ci_build   = assume_ci_build
    self.secrets_arn       = secrets_arn
    self.execution_role    = execution_role
    self.task_role         = task_role
    self.dj_options        = dj_options || []
    self.fqdn              = fqdn
    self.push_allowed      = true
    self.web_options       = web_options
    self.force_build       = false
    self.registry_id       = registry_id
    self.repo_name         = repo_name
    self.variant           = 'web'

    Dir.chdir(_root)
  end

  def only_web!
    _initial_steps
    roll_out.only_web!
  end

  def run!
    _initial_steps

    roll_out.run!

    _clean_up_old_local_images!
  end

  def run_migrations!
    _initial_steps

    roll_out.run_migrations!
  end

  def bootstrap_databases!
    _initial_steps

    print "Boostrapping databases for #{target_group_name}. Are you sure? (Y/N): "
    unsure = STDIN.readline
    if unsure.chomp.upcase != 'Y'
      puts "Okay. Not running the task."
      exit
    end

    roll_out.bootstrap_databases!
  end

  def test_build!
    self.assume_ci_build = false
    self.push_allowed = false
    self.force_build = true
    _build_and_push_all!
  end

  private

  def _initial_steps
    # _ensure_clean_repo!
    _set_revision!
    _check_that_you_pushed_to_remote!
    _docker_login!
    _build_and_push_all!
    _check_secrets!
  end

  def roll_out
    @roll_out ||=
      RollOut.new({
        dj_options: dj_options,
        image_base: _remote_tag_base,
        secrets_arn: secrets_arn,
        target_group_arn: _target_group_arn,
        target_group_name: target_group_name,
        execution_role: execution_role,
        fqdn: fqdn,
        task_role: task_role,
        web_options: web_options,
      })
  end

  def _ensure_clean_repo!
    if `git status --porcelain` != ''
      puts "Aborting since git is not clean"
      exit 1
    end
  end

  def _set_revision!
    `git rev-parse HEAD > #{_assets_path}/REVISION`
  end

  def _check_that_you_pushed_to_remote!
    branch = `git rev-parse --abbrev-ref HEAD`.chomp
    remote = `git ls-remote origin | grep #{branch}`.chomp
    our_commit = `git rev-parse #{branch}`.chomp

    if ! remote.start_with?(our_commit)
      raise "Push or pull your branch first!"
    end
  end

  def _docker_login!
    resp = ecr.get_authorization_token
    data = resp.to_h[:authorization_data].first
    user, pass = Base64.decode64(data[:authorization_token]).split(/:/)
    server = data[:proxy_endpoint]
    cmd = "docker login -u #{user} -p #{pass} #{server}"
    _run(cmd, alt_msg: 'docker login')
  end

  def _build_and_push_all!
    if !_pre_cache_image_exists? || force_build
      _build_and_push_image('pre-cache')
    end
    _build_and_push_image('base')
    _build_and_push_image('web')
    _build_and_push_image('dj')
    #_build_and_push_image('cron')
  end

  def _build_and_push_image(variant)
    self.variant = variant

    unless File.exist?(_dockerfile_path)
      puts "[WARN] Not building #{variant} since the dockerfile #{_dockerfile_path} doesn't exist"
      return
    end

    _set_image_tag!

    if assume_ci_build
      while _revision_not_in_repo?
        puts "[INFO] Build did not finish yet for #{image_tag}. Trying again in #{WAIT_TIME} minutes."
        # puts "[DEBUG] These are the tags:"
        # puts _image_tags_in_repo.join(', ')

        sleep WAIT_TIME * 60
      end
    end

    if _revision_not_in_repo? || force_build
      _build!
      _tag_the_image!
      _push_image! if push_allowed
    else
      puts "[INFO] Not building or pushing image #{image_tag}. It's already in the repo."

      if ENV['PULL_LATEST'] == 'true'
        puts "Pulling just so we have it locally (it's not required)."
        _run("docker image pull #{_remote_tag}")
        _tag_the_image!(authority: 'them')
      end
    end
  end

  def _check_secrets!
    secretsmanager.describe_secret(secret_id: secrets_arn)
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    puts "Cannot find #{secrets_arn}. Aborting"
    exit
  end

  def _set_image_tag!
    if variant == 'pre-cache'
      self.image_tag = 'latest--pre-cache'
    elsif ENV['IMAGE_TAG']
      self.image_tag = ENV['IMAGE_TAG'] + "--#{variant}"
    else
      version = `git rev-parse --short=9 HEAD`.chomp
      self.image_tag = "#{version}--#{variant}"
    end

    # puts "Setting image tag to #{image_tag}"
  end

  def _build!
    _run(<<~CMD)
      docker build
        --file=#{_dockerfile_path}
        --tag #{repo_name}:latest--#{self.variant}
        .
    CMD
  end

  def _tag_the_image!(authority: 'us')
    if authority == 'us'
      _run("docker image tag #{repo_name}:latest--#{self.variant} #{_remote_tag}")
    elsif authority == 'them'
      _run("docker image tag #{_remote_tag} #{repo_name}:latest--#{self.variant} ")
    else
      raise 'invalid authority'
    end
  end

  # This is a crude thing, but hopefully will inspire something not crude
  def _test_stack!
    _run("tmux split-window -h")
    _run("tmux send-keys :1 'cd config/deploy/docker/local-test'")

    puts "Sleeping to let stack boot"
    sleep 20

    _run(<<~CMD)
      curl -k -H 'Host: #{TEST_HOST}' https://localhost:#{TEST_PORT}
    CMD
  end

  def debug?
    ENV['DEBUG']=='true'
  end

  def _push_image!
    if debug?
      puts "Skipping pushing to remote"
      return
    end

    _run("docker push #{_remote_tag}")
    _run("docker push #{_remote_latest_tag}")
  end

  def _clean_up_old_local_images!
    _run(<<~CMD)
      docker image prune --force -a --filter 'label=app=#{repo_name}' --filter 'until=100h'
    CMD
  end

  def _image_tags_in_repo
    params = {
      registry_id: registry_id,
      repository_name: repo_name,
      max_results: 100,
      filter: {
        tag_status: "TAGGED",
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

  def _pre_cache_image_exists?
    result = `docker image ls -f 'reference=#{repo_name}' | grep latest--pre-cache`

    !result.match?(/^\s*$/)
  end

  def _remote_tag
    repo_url + ":" + image_tag
  end

  def _remote_latest_tag
    repo_url + ":" + "latest--#{self.variant}"
  end

  def _remote_tag_base
    _remote_tag.reverse.sub(/^(\w+--)?/, '').reverse
  end

  def _run(c, alt_msg: nil)
    cmd = c.gsub(/\n/, ' ').squeeze(' ')
    puts "Running #{alt_msg||cmd}"

    system(cmd)

    if $CHILD_STATUS.exitstatus != 0
      raise "Aborting deployment due to command error"
    end
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

  define_method(:elbv2) { Aws::ElasticLoadBalancingV2::Client.new(profile: AWS_PROFILE) }
  define_method(:ecr) { Aws::ECR::Client.new(profile: AWS_PROFILE) }
  define_method(:secretsmanager) { Aws::SecretsManager::Client.new(profile: AWS_PROFILE) }
end
