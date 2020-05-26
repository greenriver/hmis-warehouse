#!/usr/bin/env ruby

require_relative 'scheduled_task'
require 'aws-sdk-iam'
require 'aws-sdk-ecs'
require 'time'

# Run from rails root

class CronInstaller
  def run!
    entry_number = 0

    ScheduledTask.clear!(target_group_name)

    each_cron_entry do |cron_expression, command|
      params = {
        target_group_name: target_group_name,
        schedule_expression: cron_expression,
        description: command.join(' '),
        offset: entry_number,
        cluster_name: ENV.fetch('CLUSTER_NAME'),
        role_arn: role_arn,
        task_definition_arn: task_definition_arn,
        command: command,
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

    raise "No task definition found" if task_definition.nil?

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

    (minute, hour, day_of_month, month, day_of_week) = tokens[0,5]

    year = '*'

    # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions
    if day_of_month == '*' && day_of_week == '*'
      day_of_week = '?'
    end

    # This isn't strictly correct, but hopefully good enough
    utc_hour =
      if !hour.include?('*')
        #ENV["TZ"] ||= "US/Eastern"
        hour.split(',').map do |h|
          #Time.parse("#{h}:00").to_datetime.utc.hour
          ((h.to_i + 4)%24).to_s
        end.join(',')
      else
        hour
      end

    "cron(#{minute}, #{utc_hour}, #{day_of_month}, #{month}, #{day_of_week}, #{year})".tap do |expression|
      puts "[INFO] cron expression is #{expression}"
    end

  end

  def get_command(line)
    reg_match = line.match(%r{/bin/bash -l -c '(.+)'$})

    raise "invalid cron line" if reg_match.nil?

    command = reg_match[1]

    command = command.split(/&&/).last

    raise "invalid cron line" if command.nil?

    command.sub!(/^\s*RAILS_ENV=\w+ /, '')

    command.strip!

    command.split(' ')
  end

  define_method(:iam) { Aws::IAM::Client.new }
  define_method(:ecs) { Aws::ECS::Client.new }
end

CronInstaller.new.run!
