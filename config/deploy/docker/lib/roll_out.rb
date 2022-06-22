require 'English'
require 'amazing_print'
require 'yaml'
require 'pty'
require_relative 'ecs_tools'
require_relative 'memory_analyzer'
require 'aws-sdk-cloudwatchlogs'
require 'aws-sdk-ec2'
require_relative '../../../../app/jobs/workoff_arbiter'
require_relative 'shared_logic'
require_relative 'aws_sdk_helpers'

# rubocop:disable Style/RedundantSelf
class RollOut
  attr_accessor :aws_profile
  attr_accessor :cluster
  attr_accessor :default_environment
  attr_accessor :deployment_id # Used to verify when the deploy_tasks script finishes
  attr_accessor :dj_options
  attr_accessor :execution_role
  attr_accessor :image_base
  attr_accessor :last_task_completed
  attr_accessor :log_prefix
  attr_accessor :log_stream_name
  attr_accessor :rails_env
  attr_accessor :secrets_arn
  attr_accessor :service_exists
  attr_accessor :status_uri
  attr_accessor :target_group_arn
  attr_accessor :target_group_name
  attr_accessor :task_definition
  attr_accessor :task_role
  attr_accessor :web_options
  attr_accessor :only_check_ram

  include SharedLogic
  include AwsSdkHelpers::Helpers

  # FIXME: cpu shares as parameter
  # FIXME: log level as parameter

  DEFAULT_SOFT_WEB_RAM_MB = 1800

  DEFAULT_SOFT_DJ_RAM_MB = ->(target_group_name) { target_group_name.match?(/staging/) ? 1500 : 4000 }

  DEFAULT_SOFT_RAM_MB = 1800

  RAM_OVERCOMMIT_MULTIPLIER = ->(target_group_name) { target_group_name.match?(/staging/) ? 5 : 3 }

  DEFAULT_CPU_SHARES = 256

  NOT_SPOT = 'not-spot'.freeze

  def initialize(image_base:, target_group_name:, target_group_arn:, secrets_arn:, execution_role:, task_role:, dj_options: nil, web_options:, fqdn:, capacity_providers:)
    self.cluster             = _cluster_name
    self.image_base          = image_base
    self.secrets_arn         = secrets_arn
    self.target_group_arn    = target_group_arn
    self.target_group_name   = target_group_name
    self.execution_role      = execution_role
    self.task_role           = task_role
    self.dj_options          = dj_options
    self.web_options         = web_options
    self.status_uri          = URI("https://#{fqdn}/system_status/details")
    self.only_check_ram      = false
    @capacity_providers      = capacity_providers

    if task_role.nil? || task_role.match(/^\s*$/)
      puts "\n[WARN] task role was not set. The containers will use the role of the entire instance\n\n"
      self.task_role = nil
    end

    # Comment this out if you want to bypass checking on deploy task completion
    if _get_status == {} && ! ENV['FIRST'] == 'true'
      puts "Status uri #{self.status_uri} isn't correct"
      exit
    end

    if target_group_name.match?(/production|prd/)
      self.rails_env = 'production'
    elsif target_group_name.match?(/staging|stg/)
      self.rails_env = 'staging'
    else
      raise 'Cannot figure out environment from target_group_name!'
    end

    deployed_at = Date.today.to_s
    deployed_by = ENV['USER'] || 'unknown'

    # when the deploy tasks complete, it updates a redis key
    # with this value. We can then ping the app to see when this happens at
    # system_status/details.
    self.deployment_id = [
      deployed_at,
      deployed_by[0, 3], # A little anonymity
      File.read("#{Deployer::ASSETS_PATH}/REVISION").chomp,
      SecureRandom.hex(6),
    ].join('::')

    puts "[INFO] DEPLOYMENT_ID=#{self.deployment_id} #{target_group_name}"

    self.default_environment = [
      { 'name' => 'ECS', 'value' => 'true' },
      { 'name' => 'LOG_LEVEL', 'value' => 'info' },
      { 'name' => 'TARGET_GROUP_NAME', 'value' => target_group_name },
      { 'name' => 'DEPLOYED_AT', 'value' => deployed_at },
      { 'name' => 'DEPLOYED_BY', 'value' => deployed_by },
      { 'name' => 'AWS_REGION', 'value' => ENV.fetch('AWS_REGION') { 'us-east-1' } },
      { 'name' => 'SECRET_ARN', 'value' => secrets_arn },
      { 'name' => 'CLUSTER_NAME', 'value' => self.cluster },
      { 'name' => 'RAILS_ENV', 'value' => rails_env },
      { 'name' => 'DEPLOYMENT_ID', 'value' => self.deployment_id },
      # { "name" => "RAILS_MAX_THREADS", "value" => '5' },
      # { "name" => "WEB_CONCURRENCY", "value" =>  '2' },
      # { "name" => "PUMA_PERSISTENT_TIMEOUT", "value" =>  '70' },
    ]
  end

  def only_web!
    # run_deploy_tasks!
    deploy_web!
  end

  def run!
    # Needs to go first so the others can know the task definition
    register_workoff_worker!

    register_cron_job_worker!

    run_deploy_tasks!

    deploy_web!

    dj_options.each do |dj_options|
      deploy_dj!(dj_options)
    end
  end

  def check_ram!
    self.only_check_ram = true

    deploy_web!

    dj_options.each do |dj_options|
      deploy_dj!(dj_options)
    end
  end

  def bootstrap_databases!
    name = target_group_name + '-bootstrap-dbs'

    _register_task!(
      soft_mem_limit_mb: DEFAULT_SOFT_RAM_MB,
      image: image_base + '--dj',
      name: name,
      command: ['bin/db_prep'],
    )

    _run_task!
  end

  def run_deploy_tasks!
    name = target_group_name + '-deploy-tasks'

    _register_task!(
      soft_mem_limit_mb: DEFAULT_SOFT_RAM_MB,
      image: image_base + '--deploy',
      name: name,
      command: ['bin/deploy_tasks.sh'],
    )

    _run_task!
  end

  def register_cron_job_worker!
    _make_cloudwatch_group!

    name = target_group_name + '-cron-worker'

    _register_task!(
      soft_mem_limit_mb: DEFAULT_SOFT_DJ_RAM_MB.call(target_group_name),
      image: image_base + '--dj',
      name: name,
      # command: ['echo', 'workerhere'],
    )
  end

  def register_workoff_worker!
    name = target_group_name + '-workoff'

    _register_task!(
      soft_mem_limit_mb: DEFAULT_SOFT_RAM_MB,
      image: image_base + '--dj',
      name: name,
      command: ['rake', 'jobs:workoff'],
    )

    self.default_environment << { name: 'WORKOFF_TASK_DEFINITION', value: self.task_definition }
  end

  def web_soft_mem_limit_mb
    (web_options['soft_mem_limit_mb'] || DEFAULT_SOFT_WEB_RAM_MB).to_i
  end

  def deploy_web!
    _make_cloudwatch_group!

    name = target_group_name + '-web'

    soft_mem_limit_mb = (web_options['soft_mem_limit_mb'] || DEFAULT_SOFT_WEB_RAM_MB).to_i

    environment = default_environment.dup

    _register_task!(
      soft_mem_limit_mb: soft_mem_limit_mb,
      image: image_base + '--web',
      environment: environment,
      ports: [
        {
          'container_port' => 3000,
          'host_port' => 0,
          'protocol' => 'tcp',
        },
      ],
      name: name,
    )

    return if self.only_check_ram

    lb = [
      {
        target_group_arn: target_group_arn,
        container_name: name,
        container_port: 3000,
      },
    ]

    minimum, maximum = _get_min_max_from_desired(web_options['container_count'])

    # Keep production web containers on on-demand providers
    _start_service!(
      capacity_provider: _on_demand_capacity_provider_name,
      name: name + '-2', # version bump for change from port 443 -> 3000
      load_balancers: lb,
      desired_count: web_options['container_count'] || 1,
      minimum_healthy_percent: minimum,
      maximum_percent: maximum,
    )
  end

  def deploy_dj!(dj_options)
    name = target_group_name + "-dj-#{dj_options['name']}"

    environment = default_environment.dup

    dj_options['env'].each do |key, value|
      environment << { 'name' => key, 'value' => value }
    end

    default_ram = DEFAULT_SOFT_DJ_RAM_MB.call(target_group_name)

    soft_mem_limit_mb = (dj_options['soft_mem_limit_mb'] || default_ram).to_i

    _register_task!(
      soft_mem_limit_mb: soft_mem_limit_mb,
      image: image_base + '--dj',
      name: name,
      environment: environment,
    )

    return if self.only_check_ram

    minimum, maximum = _get_min_max_from_desired(dj_options['container_count'])

    _start_service!(
      name: name,
      capacity_provider: _on_demand_capacity_provider_name,
      desired_count: dj_options['container_count'] || 1,
      maximum_percent: maximum,
      minimum_healthy_percent: minimum,
    )
  end

  private

  def _get_min_max_from_desired(container_count)
    desired_count = container_count || 1

    return [0, 100] if desired_count.zero?

    if desired_count == 1
      [100, 200]
    else
      chunk_size = (100 / desired_count) + 1

      [chunk_size, 100 + chunk_size * 2]
    end
  end

  def _make_cloudwatch_group!
    cwl.create_log_group(log_group_name: target_group_name)
  rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
    # puts "[DEBUG] Log group #{target_group_name} exists." if @seen.nil?
    @seen = true
  end

  def _register_task!(name:, image:, cpu_shares: nil, soft_mem_limit_mb: 512, ports: [], environment: nil, command: nil, stop_timeout: 30)
    puts "[INFO] Registering #{name} task #{target_group_name}"

    environment ||= default_environment.dup

    # https://aws.amazon.com/ec2/instance-types/
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions
    # multiply the number of vCPUs by 1024 for the total possible on an
    # instance. Any unused get divided up at the same ratio as all the
    # containers running.
    # Increase this to limit number of containers on a box if there are cpu capacity issues.
    cpu_shares ||= DEFAULT_CPU_SHARES

    memory_multiplier = RAM_OVERCOMMIT_MULTIPLIER.call(target_group_name)

    self.log_prefix = name.split(/ecs/).last.sub(/^-/, '') +
      '/' +
      Time.now.strftime('%Y-%m-%d:%H-%M%Z').gsub(/:/, '_')

    # This is just reverse-engineering what ECS is doing.
    # I'm not sure if there's a way to simplify the stream name
    # This won't be a complete and valid stream name until TASK_ID is
    # substituted later on
    self.log_stream_name = "#{log_prefix}/#{name}/TASK_ID"
    environment << { 'name' => 'LOG_STREAM_NAME_PREFIX', 'value' => "#{log_prefix}/#{name}" }

    ten_minutes = 10 * 60

    hard_mem_limit_mb = (soft_mem_limit_mb * memory_multiplier).to_i

    ma = MemoryAnalyzer.new
    ma.cluster_name         = self.cluster
    ma.task_definition_name = name
    ma.bootstrapped_hard_limit_mb = hard_mem_limit_mb
    ma.bootstrapped_soft_limit_mb = soft_mem_limit_mb
    ma.run!

    return if self.only_check_ram

    container_definition = {
      name: name,
      image: image,
      cpu: cpu_shares,

      # Hard limit
      memory: (ma.use_memory_analyzer? ? ma.recommended_hard_limit_mb : hard_mem_limit_mb),

      # Soft limit
      memory_reservation: (ma.use_memory_analyzer? ? ma.recommended_soft_limit_mb : soft_mem_limit_mb),

      port_mappings: ports,
      essential: true,
      environment: environment,
      start_timeout: ten_minutes,
      stop_timeout: stop_timeout,
      # entry_point: ["String"],
      # health_check: { },
      secrets: [
        # { name: "SOME_PASSWORD", value_from: some_passowrd_secrets_arn, },
      ],
      log_configuration: {
        log_driver: 'awslogs',
        options: {
          'awslogs-group' => target_group_name,
          'awslogs-region' => 'us-east-1',
          'awslogs-stream-prefix' => log_prefix,
        },
      },
    }

    puts "[INFO] hard RAM limit: #{container_definition[:memory]} #{target_group_name}"
    puts "[INFO] soft RAM limit: #{container_definition[:memory_reservation]} #{target_group_name}"

    container_definition[:command] = command unless command.nil?

    task_definition_payload = {
      container_definitions: [container_definition],

      family: name,

      # This is the role that the ECS agent and Docker daemon can assume
      execution_role_arn: execution_role,
    }

    # This is the role that the service/task can assume
    task_definition_payload[:task_role_arn] = task_role unless task_role.nil?

    results = ecs.register_task_definition(task_definition_payload)

    self.task_definition = results.to_h.dig(:task_definition, :task_definition_arn)
  end

  def _run_task!
    _make_cloudwatch_group!

    puts "[INFO] Running task: #{task_definition} #{target_group_name}"

    incomplete = true

    run_task_payload = {
      cluster: cluster,
      task_definition: task_definition,
    }

    if _capacity_providers.length.positive?
      puts "[INFO] Using spot capacity provider: #{_spot_capacity_provider_name} #{target_group_name}"
      run_task_payload[:capacity_provider_strategy] = [
        {
          capacity_provider: _spot_capacity_provider_name,
          weight: 1,
          base: 1,
        },
      ]
    else
      puts "[ERROR] No dynamic work capacity provider found. Just running the task. #{target_group_name}"
    end

    while incomplete
      results = ecs.run_task(run_task_payload)

      if results.failures.length.positive?
        # FIXME: we can look up the ec2 instance name container instance -> ec2 instance -> tags -> name tag
        # results = ecs.describe_container_instances( container_instances: results.failures.map(&:arn), cluster: cluster).container_instances
        # ec2_instances ||= ec2.describe_instance.instances
        # lookup = Hash[
        #   results.map do |r|
        #     ec2_instances.find { |i| i.
        #     [r.container_instance_arn, r.ec2_instance_id]
        #   end
        # ]

        results.failures.each do |failure|
          puts "[FATAL] NOT ENOUGH #{failure.reason} on #{failure.arn} #{target_group_name}"
        end
        puts "[WARN] The last task did not run. Trying again (hopefully more capacity will free up)... #{target_group_name}"
        sleep 20
        incomplete = true
      else
        incomplete = false
      end
    end

    task_arn = results.tasks.first&.task_arn

    if task_arn.nil?
      puts "[FATAL] Something went wrong with the task. exiting #{target_group_name}"
      exit
    end

    puts "[INFO] Task arn: #{task_arn || 'unknown'} #{target_group_name}"
    puts "[INFO] Debug with: aws ecs describe-tasks --cluster #{cluster} --tasks #{task_arn} #{target_group_name}"

    results = ecs.describe_tasks(cluster: cluster, tasks: [task_arn])

    if results.failures.length.positive?
      puts "[FATAL] failures: #{results.failures} #{target_group_name}"
      exit
    end

    failure_reasons = results.tasks.flat_map { |x| x.containers.map(&:reason) }.compact

    if failure_reasons.length.positive?
      puts "[FATAL] failures: #{failures_reasons} #{target_group_name}"
      exit
    end

    task_id = task_arn.split('/').last
    log_stream_name.sub!(/TASK_ID/, task_id)

    puts "[INFO] Waiting on the task to start... #{target_group_name}"
    begin
      ecs.wait_until(:tasks_running, { cluster: cluster, tasks: [task_arn] }, { max_attempts: 25, delay: 10 })
    rescue Aws::Waiters::Errors::TooManyAttemptsError => _e
      puts "[WARN] Task didn't start in time. Trying again."

      ecs.stop_task(cluster: cluster, task: task_arn)
      _run_task!
    end

    _tail_logs
  end

  def _get_status
    raw = Net::HTTP.get(status_uri)
    JSON.parse(raw)
  rescue Errno::EADDRNOTAVAIL, SocketError, JSON::ParserError
    {}
  end

  # If you can construct or query for the log stream name, you can use this to
  # tail any tasks, even those that are part of a service.
  def _tail_logs
    begin
      _resp = cwl.get_log_events(
        {
          log_group_name: target_group_name,
          log_stream_name: log_stream_name,
          start_from_head: true,
        },
      )
    rescue Aws::CloudWatchLogs::Errors::ResourceNotFoundException
      puts "[FATAL] The log stream #{log_stream_name} does not exist. At least not yet. Waiting 30 seconds...#{target_group_name}"
      sleep 30
      _tail_logs
    end
    begin
      cmd = "aws logs tail #{target_group_name} --follow --log-stream-names=#{log_stream_name}"
      PTY.spawn(cmd) do |stdout, _stdin, _pid|
        stdout.each do |line|
          print line
          if line.match?(/---DONE---/)
            puts 'found ---DONE---, exiting'
            return true
          end
        end
      rescue Errno::EIO
        puts '[WARN] Errno:EIO error, but this probably just meams that the process has finished giving output'
        return false
      end
    rescue PTY::ChildExited
      puts '[WARN] The child process exited!'
      return false
    end
  end

  def _start_service!(capacity_provider:, load_balancers: [], desired_count: 1, name:, maximum_percent: 100, minimum_healthy_percent: 0)
    services = ecs.list_services({ cluster: cluster })

    # services result is paginated. The first any iterates over each page
    service_exists = services.any? do |results|
      # This check the page for the service we're looking for
      results.to_h[:service_arns].any? { |arn| arn.include?(name) }
    end

    five_minutes = 5 * 60

    if service_exists
      puts "[INFO] Updating #{name} to #{task_definition.split(/:/).last}: #{desired_count} containers #{target_group_name}"
      payload = {
        cluster: cluster,
        service: name,
        desired_count: desired_count,
        task_definition: task_definition,
        force_new_deployment: true, # Need this when you change capacity providers. TODO: detect this situation
        capacity_provider_strategy: [
          {
            capacity_provider: capacity_provider,
            weight: 1,
            base: 1,
          },
        ],
        placement_strategy: _placement_strategy,
        deployment_configuration: {
          maximum_percent: maximum_percent,
          minimum_healthy_percent: minimum_healthy_percent,
          deployment_circuit_breaker: {
            enable: true,
            rollback: true,
          },
        },
      }

      payload[:health_check_grace_period_seconds] = five_minutes if load_balancers.length.positive?

      ecs.update_service(payload)
    else
      puts "[INFO] Creating #{name} #{target_group_name}"
      payload = {
        cluster: cluster,
        service_name: name,
        desired_count: desired_count,
        task_definition: task_definition,
        capacity_provider_strategy: [
          {
            capacity_provider: capacity_provider,
            weight: 1,
            base: 1,
          },
        ],
        deployment_configuration: {
          maximum_percent: maximum_percent,
          minimum_healthy_percent: minimum_healthy_percent,
        },
        placement_strategy: _placement_strategy,
        load_balancers: load_balancers,
      }

      payload[:health_check_grace_period_seconds] = five_minutes if load_balancers.length.positive?

      ecs.create_service(payload)
    end
  end

  def _run(command)
    cmd = command.gsub(/\n/, ' ').squeeze(' ')
    puts "Running #{cmd}"

    system(cmd)

    raise 'Aborting deployment due to command error' if $CHILD_STATUS.exitstatus != 0
  end
end
# rubocop:enable Style/RedundantSelf
