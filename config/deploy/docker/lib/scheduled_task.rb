# This encapsulates the concept of a single recurring task

require 'aws-sdk-cloudwatchevents'
require 'aws-sdk-ecs'

class ScheduledTask
  attr_accessor :cluster_name
  attr_accessor :command
  attr_accessor :description
  attr_accessor :offset
  attr_accessor :role_arn
  attr_accessor :schedule_expression
  attr_accessor :target_group_name
  attr_accessor :task_definition_arn

  MAX_NAME_LENGTH = 64

  def initialize(params)
    params.each do |name, value|
      send("#{name}=", value)
    end
  end

  def run!
    make_rule!
    add_target!
  end

  def name
    suffix = (0.upto(9).to_a +  'A'.upto('Z').to_a)[offset]

    ideal_name = "#{target_group_name}#{suffix}"

    if ideal_name.length > MAX_NAME_LENGTH
      puts "[ERROR] #{ideal_name} was too long. Needs to be shorter for #{schedule_expression}: #{description}. Aborting"
      exit 1
    else
      ideal_name
    end
  end

  def self.clear!(target_group_name)
    resp = cloudwatchevents.list_rules(
      name_prefix: target_group_name,
    )

    resp.each do |set|
      set.rules.each do |rule|
        target_ids =
          cloudwatchevents.list_targets_by_rule(
            rule: rule.name
          ).flat_map do |set|
            set.targets.map(&:id)
          end

        if target_ids.length > 0
          puts "[INFO] Deleting #{target_ids.join(', ')} in rule #{rule.name}"
          cloudwatchevents.remove_targets(
            rule: rule.name,
            ids: target_ids,
          )
        end

        puts "[INFO] Removing associated and now empty rule: #{rule.name}"
        cloudwatchevents.delete_rule(name: rule.name)
      end
    end
  end

  private

  def make_rule!
    # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html

    payload = {
      name: name,
      schedule_expression: schedule_expression,
      state: "ENABLED", # accepts ENABLED, DISABLED
      description: description,
      tags: [
        {
          key: "CreatedBy",
          value: ENV.fetch('USER') { 'unknown' },
        },
        {
          key: "target_group_name",
          value: target_group_name,
        },
      ],
    }

    print "[INFO] Attempting to make rule for #{schedule_expression}: #{description}"

    cloudwatchevents.put_rule(payload)

    # puts "[INFO] Made rule #{name}"
  end

  def add_target!
    input = {
      "containerOverrides" => [
        _container_overrides
      ]
    }.to_json

    payload = {
      rule: name,
      targets: [
        {
          id: name,
          arn: cluster_arn,
          role_arn: role_arn,
          input: input,
          ecs_parameters: {
            task_definition_arn: task_definition_arn,
            task_count: 1,
            # Issues with this put_targets working? Try removing capacity
            # provider line and using launch_type only.
            # https://github.com/aws/containers-roadmap/issues/937
            # launch_type: "EC2",
            capacity_provider_strategy: _default_capacity_provider_strategy,
          },
        },
      ],
    }

    cloudwatchevents.put_targets(payload)

    puts "... Added target to #{name}"
  end

  def _default_capacity_provider_strategy
    our_cluster = ecs.describe_clusters(clusters: [cluster_name]).clusters.first
    our_cluster.default_capacity_provider_strategy.map(&:to_h)
  end

  def _container_overrides
    overrides = {
      # This is the name of the container in the task definition.
      # It needs to match or this doesn't work
      # FIXME: pull from task definition. maybe we should just always call
      # it 'app'
      "name" => "#{target_group_name}-cron-worker",
      "command" => command,
    }

    resource_adjustments =
      if command.any? { |token| token == 'jobs:arbitrate_workoff' }
        print " (Modifying RAM for arbitrate workoff: 800/400) "
        { 'memory' => 800, 'memoryReservation' => 400 }
      else
        {}
      end

    overrides.merge(resource_adjustments)
  end

  def cluster_arn
    ecs.list_clusters.cluster_arns.find { |x| x.match?(/#{cluster_name}/) }
  end

  define_singleton_method(:cloudwatchevents) { Aws::CloudWatchEvents::Client.new }
  define_method(:cloudwatchevents) { Aws::CloudWatchEvents::Client.new }
  define_method(:ecs) { Aws::ECS::Client.new }
end
