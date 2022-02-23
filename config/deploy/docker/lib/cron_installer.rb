#!/usr/bin/env ruby

require_relative 'scheduled_task'
require_relative 'aws_sdk_helpers'
require 'time'

# Run from rails root

class CronInstaller
  include AwsSdkHelpers::Helpers

  MAX_DESCRIPTION_LENGTH = 512

  def run!
    entry_number = 0

    ScheduledTask.clear!(target_group_name)

    each_cron_entry do |cron_expression, command|
      capacity_provider_strategy = _choose_capacity_provider_strategy(command)
      command.delete('#capacity_provider:spot')
      description = command.join(' ').sub(/ --silent/, '').sub(/bundle exec /, '')[0, MAX_DESCRIPTION_LENGTH]

      params = {
        target_group_name: target_group_name,
        schedule_expression: cron_expression,
        description: description,
        offset: entry_number,
        cluster_name: ENV.fetch('CLUSTER_NAME'),
        role_arn: role_arn,
        task_definition_arn: task_definition_arn,
        command: command,
        capacity_provider_strategy: capacity_provider_strategy,
      }

      scheduled_task = ScheduledTask.new(params)
      scheduled_task.run!

      entry_number += 1
    end
  end

  private

  def target_group_name
    ENV.fetch('TARGET_GROUP_NAME')
  end

  def role_arn
    @role_arn ||= iam.get_role(role_name: 'ecsEventsRole').role.arn
  end

  def _choose_capacity_provider_strategy(command)
    return _spot_capacity_provider_strategy if command.include?('#capacity_provider:spot')

    _on_demand_capacity_provider_strategy
  end

  def _spot_capacity_provider_strategy
    [
      {
        capacity_provider: _spot_capacity_provider_name,
        weight: 1,
        base: 1,
      },
    ]
  end

  def _on_demand_capacity_provider_strategy
    [
      {
        capacity_provider: _on_demand_capacity_provider_name,
        weight: 1,
        base: 1,
      },
    ]
  end

  def task_definition_arn
    return @task_definition_arn unless @task_definition_arn.nil?

    families = ecs.list_task_definition_families(family_prefix: target_group_name).families

    raise "No families found for #{target_group_name}" if families == []

    family = families.find { |x| x.match(/cron-worker/) }

    raise "No family found for #{target_group_name} that looks like a worker" if family.nil?

    puts "[INFO] Using #{family}"

    task_definition = ecs.list_task_definitions(
      status: 'ACTIVE',
      family_prefix: family,
      sort: 'DESC',
      max_results: 1,
    ).task_definition_arns.first

    raise 'No task definition found' if task_definition.nil?

    puts "[INFO] Using #{task_definition}"

    @task_definition_arn = task_definition
  end

  def each_cron_entry
    `whenever`.each_line do |line|
      next if line.match?(/^\s*$/)
      next if line.match?(/^\s*#/)

      yield get_cron_expression(line), get_command(line)
    end
  end

  def get_cron_expression(line)
    tokens = line.split(' ')

    (minute, hour, day_of_month, month, day_of_week) = tokens[0, 5]

    year = '*'

    # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions
    if day_of_month == '*' && day_of_week == '*'
      day_of_week = '?'
    elsif day_of_month != '*'
      day_of_week = '?'
    end

    utc_hour =
      if !hour.include?('*')
        hour.split(',').map do |h|
          # utc_offset is how far our time is from UTC in seconds.
          # hour_correction converts to hours and is the opposite sign since
          # we're converting to UTC. If we're 5 hours behind UTC (-5) we need
          # to add 5 hours to get to UTC from our local time.
          hour_correction = -1 * (Time.now.utc_offset / 60.0 / 60.0).to_i

          ((h.to_i + hour_correction) % 24).to_s
        end.join(',')
      else
        hour
      end

    "cron(#{minute}, #{utc_hour}, #{day_of_month}, #{month}, #{day_of_week}, #{year})"
  end

  def get_command(line)
    reg_match = line.match(/\/bin\/bash -l -c '(.+)'$/)

    raise 'invalid cron line' if reg_match.nil?

    command = reg_match[1]

    command = command.split(/&&/).last

    raise 'invalid cron line' if command.nil?

    command.sub!(/^\s*RAILS_ENV=\w+ /, '')

    command.strip!

    command.split(' ')
  end
end

CronInstaller.new.run!
