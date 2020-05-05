require 'English'
require 'awesome_print'
require 'yaml'
require_relative 'ecs_tools'
require 'aws-sdk-cloudwatchlogs'
# require 'aws-sdk-ec2'

class RollOut
  attr_accessor :aws_profile
  attr_accessor :cluster
  attr_accessor :dj_options
  attr_accessor :web_options
  attr_accessor :image_base
  attr_accessor :secrets_arn
  attr_accessor :service_exists
  attr_accessor :target_group_arn
  attr_accessor :target_group_name
  attr_accessor :task_definition
  attr_accessor :task_role
  attr_accessor :execution_role
  attr_accessor :default_environment
  attr_accessor :log_prefix
  attr_accessor :log_stream_name

  # FIXME: cpu shares as parameter
  # FIXME: log level as parameter

  DEFAULT_SOFT_WEB_RAM_MB = 1800

  DEFAULT_SOFT_DJ_RAM_MB = ->(target_group_name) { target_group_name.match?(/staging/) ? 2000 : 6000 }

  DEFAULT_SOFT_RAM_MB = 1800

  RAM_OVERCOMMIT_MULTIPLIER = 1.6

  DEFAULT_CPU_SHARES = 256

  def initialize(image_base:, target_group_name:, target_group_arn:, secrets_arn:, execution_role:, task_role:, dj_options: nil, web_options:)
    self.aws_profile         = ENV.fetch('AWS_PROFILE')
    self.cluster             = ENV.fetch('AWS_CLUSTER') { self.aws_profile }
    self.image_base          = image_base
    self.secrets_arn         = secrets_arn
    self.target_group_arn    = target_group_arn
    self.target_group_name   = target_group_name
    self.execution_role      = execution_role
    self.task_role           = task_role
    self.dj_options          = dj_options
    self.web_options         = web_options

    self.default_environment = [
      { "name" => "ECS", "value" => "true" },
      { "name" => "LOG_LEVEL", "value" => "info" },
      { "name" => "TARGET_GROUP_NAME", "value" => target_group_name },
      { "name" => "DEPLOYED_AT", "value" => Date.today.to_s },
      { "name" => "DEPLOYED_BY", "value" => ENV['USER']||'unknown' },
      { "name" => "AWS_REGION", "value" => ENV.fetch('AWS_REGION') { 'us-east-1' } },
      { "name" => "SECRET_ARN", "value" => secrets_arn },
      { "name" => "CLUSTER_NAME", "value" => self.cluster },
    ]
  end

  def only_web!
    # run_deploy_tasks!
    deploy_web!
  end

  def run!
    register_cron_job_worker!

    run_deploy_tasks!

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
      command: ['bin/db_prep']
    )

    _run_task!
  end

  def run_deploy_tasks!
    name = target_group_name + '-deploy-tasks'

    _register_task!(
      soft_mem_limit_mb: DEFAULT_SOFT_RAM_MB,
      image: image_base + '--dj',
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
      command: ['echo', 'workerhere'],
    )
  end

  def deploy_web!
    name = target_group_name + '-web'

    soft_mem_limit_mb = (web_options['soft_mem_limit_mb'] || DEFAULT_SOFT_WEB_RAM_MB).to_i

    _register_task!(
      soft_mem_limit_mb: soft_mem_limit_mb,
      image: image_base + '--web',
      ports: [{
        "container_port" => 443,
        "host_port" => 0,
        "protocol" => "tcp"
      }],
      name: name,
    )

    lb = [{
      target_group_arn: target_group_arn,
      container_name: name,
      container_port: 443,
    }]

    minimum, maximum = _get_min_max_from_desired(web_options['container_count'])

    _start_service!(
      name: name,
      load_balancers: lb,
      desired_count: web_options['container_count']||1,
      minimum_healthy_percent: minimum,
      maximum_percent: maximum,
    )
  end

  def deploy_dj!(dj_options)
    name  = target_group_name + "-dj-#{dj_options['name']}"

    environment = default_environment.dup

    dj_options['env'].each do |key, value|
      environment << { "name" => key, "value" => value }
    end

    default_ram = DEFAULT_SOFT_DJ_RAM_MB.call(target_group_name)

    soft_mem_limit_mb = (dj_options['soft_mem_limit_mb'] || default_ram).to_i

    _register_task!(
      soft_mem_limit_mb: soft_mem_limit_mb,
      image: image_base + '--dj',
      name: name,
      environment: environment
    )

    minimum, maximum = _get_min_max_from_desired(dj_options['container_count'])

    _start_service!(
      name: name,
      desired_count: dj_options['container_count']||1,
      maximum_percent: maximum,
      minimum_healthy_percent: minimum,
    )
  end

  private

  def _get_min_max_from_desired(container_count)
    desired_count = container_count||1

    if desired_count == 0
      return [0,0]
    elsif desired_count == 1
      [100, 200]
    else
      chunk_size = (100 / desired_count) + 1

      [chunk_size, 100 + chunk_size*2]
    end
  end

  def _make_cloudwatch_group!
    cwl.create_log_group(
      log_group_name: target_group_name
    )
  rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
    # puts "[DEBUG] Log group #{target_group_name} exists." if @seen.nil?
    @seen = true
  end

  def _register_task!(name:, image:, cpu_shares: nil, soft_mem_limit_mb: 512, ports: [], environment: nil, command: nil, stop_timeout: 30)
    puts "[INFO] Registering #{name} task"

    environment ||= default_environment.dup

    # https://aws.amazon.com/ec2/instance-types/
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions
    # multiply the number of vCPUs by 1024 for the total possible on an
    # instance. Any unused get divided up at the same ratio as all the
    # containers running.
    # Increase this to limit number of containers on a box if there are cpu capacity issues.
    cpu_shares ||= DEFAULT_CPU_SHARES

    self.log_prefix = name.split(/ecs/).last.sub(/^-/, '') +
      '/' +
      Time.now.strftime("%Y-%m-%d:%H-%M%Z").gsub(/:/, '_')

    # This is just reverse-engineering what ECS is doing.
    # I'm not sure if there's a way to simplify the stream name
    # This won't be a complete and valid stream name until TASK_ID is
    # substituted later on
    self.log_stream_name = "#{log_prefix}/#{name}/TASK_ID"

    ten_minutes = 10 * 60

    container_definition = {
      name: name,
      image: image,
      cpu: cpu_shares,

      # Hard limit
      memory: ( soft_mem_limit_mb * RAM_OVERCOMMIT_MULTIPLIER ).to_i,

      # Soft limit
      memory_reservation: soft_mem_limit_mb,

      port_mappings: ports,
      essential: true,
      environment: environment,
      start_timeout: ten_minutes,
      stop_timeout: stop_timeout,
      #entry_point: ["String"],
      #health_check: {
      #  command: ["String"], # required
      #  interval: 1,
      #  timeout: 1,
      #  retries: 1,
      #  start_period: 1,
      #},
      secrets: [
      #  {
      #    name: "SOME_PASSWORD",
      #    value_from: some_passowrd_secrets_arn,
      #  },
      ],
      log_configuration: {
        log_driver: "awslogs",
        options: {
          "awslogs-group" => target_group_name,
          "awslogs-region" => "us-east-1",
          "awslogs-stream-prefix" => log_prefix,
        },
      },
    }

    if !command.nil?
      container_definition[:command] = command
    end

    results = ecs.register_task_definition({
      container_definitions: [ container_definition ],

      family: name,

      # This is the role that the service/task can assume
      task_role_arn: task_role,

      # This is the role that the ECS agent and Docker daemon can assume
      execution_role_arn: execution_role,
    })

    self.task_definition = results.to_h.dig(:task_definition, :task_definition_arn)
  end

  def _run_task!
    _make_cloudwatch_group!

    start_time = Time.now

    puts "[INFO] Running task: #{task_definition}"

    incomplete = true

    while (incomplete) do
      results = ecs.run_task(
        cluster: cluster,
        task_definition: task_definition
      )

      if results.failures.length > 0
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
          puts "[FATAL] NOT ENOUGH #{failure.reason} on #{failure.arn}"
        end
        puts "[WARN] The last task did not run. Trying again (hopefully more capacity will free up)..."
        sleep 20
        incomplete = true
      else
        incomplete = false
      end
    end

    task_arn = results.tasks.first&.task_arn

    if task_arn.nil?
      puts "[FATAL] Something went wrong with the task. exiting"
      exit
    end

    puts "[INFO] Task arn: #{task_arn||'unknown'}"
    puts "[INFO] Debug with: aws ecs describe-tasks --cluster #{cluster} --tasks #{task_arn}"

    puts '[INFO] Waiting on the task to start and finish quickly to catch resource-related errors'
    begin
      ecs.wait_until(:tasks_running, {cluster: cluster, tasks: [task_arn]}, {max_attempts: 5, delay: 5})
    rescue Aws::Waiters::Errors::TooManyAttemptsError
    end
    begin
      ecs.wait_until(:tasks_stopped, {cluster: cluster, tasks: [task_arn]}, {max_attempts: 2, delay: 5})
    rescue Aws::Waiters::Errors::TooManyAttemptsError
    end

    results = ecs.describe_tasks(cluster: cluster, tasks: [task_arn])

    if results.failures.length > 0
      puts "[FATAL] failures: #{results.failures}"
      exit
    end

    failure_reasons = results.tasks.flat_map { |x| x.containers.map { |c| c.reason } }.compact

    if failure_reasons.length > 0
      puts "[FATAL] failures: #{failures_reasons}"
      exit
    end

    task_id = task_arn.split('/').last
    log_stream_name.sub!(/TASK_ID/, task_id)

    _tail_logs(start_time)
  end

  # If you can construct or query for the log stream name, you can use this to
  # tail any tasks, even those that are part of a service.
  def _tail_logs(start_time=Time.now)
    begin
      resp = cwl.get_log_events({
        log_group_name: target_group_name,
        log_stream_name: log_stream_name,
        start_time: start_time.utc.to_i,
        start_from_head: false,
      })
    rescue Aws::CloudWatchLogs::Errors::ResourceNotFoundException
      puts "[FATAL] The log stream #{log_stream_name} does not exist. At least not yet."
      return
    end

    while ( resp.events.length > 0 || (Time.now.utc.to_i - start_time.utc.to_i) < 60 )
      resp.events.each do |event|
        puts "[TASK] #{event.message}"
      end

      next_token = resp.next_forward_token

      sleep 10

      resp = cwl.get_log_events({
        log_group_name: target_group_name,
        log_stream_name: log_stream_name,
        next_token: next_token,
        start_from_head: true,
      })
    end
  end

  def _start_service!(load_balancers: [], desired_count: 1, name:, maximum_percent: 100, minimum_healthy_percent: 0)
    services = ecs.list_services({
      cluster: cluster,
    })

    # services result is paginated. The first any iterates over each page
    service_exists = services.any? do |results|
      # This check the page for the service we're looking for
      results.to_h[:service_arns].any? { |arn| arn.include?(name) }
    end

    five_minutes = 5 * 60

    if service_exists
      puts "[INFO] Updating #{name} to #{task_definition.split(/:/).last}: #{desired_count} containers"
      payload = {
        cluster: cluster,
        service: name,
        desired_count: desired_count,
        task_definition: task_definition,
        deployment_configuration: {
          maximum_percent: maximum_percent,
          minimum_healthy_percent: minimum_healthy_percent,
        }
      }

      if load_balancers.length > 0
        payload[:health_check_grace_period_seconds] = five_minutes
      end

      ecs.update_service(payload)
    else
      puts "[INFO] Creating #{name}"
      payload = {
        cluster: cluster,
        service_name: name,
        desired_count: desired_count,
        task_definition: task_definition,
        deployment_configuration: {
          maximum_percent: maximum_percent,
          minimum_healthy_percent: minimum_healthy_percent,
        },
        launch_type: 'EC2',
        #placement_constraints:  [
        #  { type: 'distinctInstance' },
        #],
        placement_strategy: [
          {
            "field": "instanceId",
            "type": "spread"
          },
          {
            "field": "attribute:ecs.availability-zone",
            "type": "spread"
          },
          {
            "type": "random"
          },
        ],
        load_balancers: load_balancers,
      }

      if load_balancers.length > 0
        payload[:health_check_grace_period_seconds] = five_minutes
      end

      ecs.create_service(payload)
    end
  end

  def _run(command)
    cmd = command.gsub(/\n/, ' ').squeeze(' ')
    puts "Running #{cmd}"

    system(cmd)

    if $CHILD_STATUS.exitstatus != 0
      raise "Aborting deployment due to command error"
    end
  end

  define_method(:ecs) { Aws::ECS::Client.new(profile: aws_profile) }
  # define_method(:ec2) { Aws::EC2::Client.new(profile: aws_profile) }
  define_method(:cwl) { Aws::CloudWatchLogs::Client.new(profile: aws_profile) }
end
