require 'English'
require 'awesome_print'
require 'yaml'
require_relative 'ecs_tools'
require 'aws-sdk-cloudwatchlogs'

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

  # FIXME: ram limit as parameter
  # FIXME: cpu shares as parameter
  # FIXME: log level as parameter

  RAM_OVERCOMMIT_MULTIPLIER = 1.6

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
      { "name" => "LOG_LEVEL", "value" => "debug" },
      { "name" => "TARGET_GROUP_NAME", "value" => target_group_name },
      { "name" => "DEPLOYED_AT", "value" => Date.today.to_s },
      { "name" => "DEPLOYED_BY", "value" => ENV['USER']||'unknown' },
      { "name" => "AWS_REGION", "value" => ENV.fetch('AWS_REGION') { 'us-east-1' } },
      { "name" => "SECRET_ARN", "value" => secrets_arn },
      { "name" => "CLUSTER_NAME", "value" => self.cluster },
    ]
  end

  def only_web!
    # run_migrations!
    deploy_web!
  end

  def run!
    run_migrations!

    deploy_web!

    dj_options.each do |dj_options|
      deploy_dj!(dj_options)
    end

    deploy_cron!
  end

  def bootstrap_databases!
    name = target_group_name + '-bootstrap-dbs'

    _register_task!(
      mem_limit_mb: 900,
      image: image_base + '--web',
      name: name,
      command: ['bin/db_prep']
    )

    _run_task!
  end

  def run_migrations!
    name = target_group_name + '-migrate'

    _register_task!(
      mem_limit_mb: 900,
      image: image_base + '--dj',
      name: name,
      # FIXME: rename this to "rake_tasks.sh" or something like that.
      command: ['bin/migrate.sh']
    )

    _run_task!
  end

  def deploy_web!
    name = target_group_name + '-web'

    _register_task!(
      mem_limit_mb: 900,
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

    _register_task!(
      mem_limit_mb: 1000,
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

  def deploy_cron!
    name  = target_group_name + "-cron-installer"

    _register_task!(
      mem_limit_mb: 1000,
      image: image_base + '--dj',
      name: name,
      command: ['bin/cron_installer.rb']
    )

    _run_task!
  end

  private

  def _get_min_max_from_desired(container_count)
    desired_count = container_count||1

    if desired_count == 0
      return [0,0]
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

  def _register_task!(name:, image:, cpu_shares: nil, mem_limit_mb: 512, ports: [], environment: nil, command: nil, stop_timeout: 30)
    puts "[INFO] Registering #{name} task"

    environment ||= default_environment.dup

    # https://aws.amazon.com/ec2/instance-types/
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions
    # multiply the number of vCPUs by 1024 for the total possible on an
    # instance. Any unused get divided up at the same ratio as all the
    # containers running.
    # Increase this to limit number of containers on a box if there are cpu capacity issues.
    cpu_shares ||= 512

    log_prefix = name.split(/ecs/).last.sub(/^-/, '')

    ten_minutes = 10 * 60

    container_definition = {
      name: name,
      image: image,
      cpu: cpu_shares,

      # Hard limit
      memory: ( mem_limit_mb * RAM_OVERCOMMIT_MULTIPLIER ).to_i,

      # Soft limit
      memory_reservation: mem_limit_mb,

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

    puts "[INFO] Running task: #{task_definition}"

    results = ecs.run_task(
      cluster: cluster,
      task_definition: task_definition
    )

    task_arn = results.tasks.first&.task_arn
    puts "Task arn: #{task_arn||'unknown'}"
    puts "Debug with: aws ecs describe-tasks --cluster #{cluster} --tasks #{task_arn}"

    # sleep 5
    # could loop on task being stopped or running
    # results = ecs.describe_tasks(
    #   cluster: cluster,
    #   tasks: [task_arn],
    # )
    # container_results = results.tasks.first.containers.first
    # puts container_results.reason
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
  define_method(:cwl) { Aws::CloudWatchLogs::Client.new(profile: aws_profile) }
end
