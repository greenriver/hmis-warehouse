###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# !/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'cronjob'
require 'time'

# Run from rails root

class CronInstaller
  MAX_DESCRIPTION_LENGTH = 512

  AMOUNT_OF_JITTER_IN_MINUTES = 10

  def run!
    Rails.logger.info "The current time is #{Time.now} and the current time in zone is #{Time.zone.now}"

    Cronjob.clear!

    each_cron_entry do |cron_expression, command|
      description = command.join(' ').sub(/ --silent/, '').sub(/bundle exec /, '')[0, MAX_DESCRIPTION_LENGTH]
      interruptable_type = command.pop
      capacity_type = nil

      case interruptable_type
      when '##interruptable=true##'
        capacity_type = 'spot'
      when '##interruptable=false##'
        capacity_type = 'on-demand'
      else
        raise "invalid interruptable type of #{interruptable_type}!"
      end

      params = {
        schedule_expression: cron_expression,
        description: description,
        command: command,
        capacity_type: capacity_type,
      }

      Cronjob.new(**params).run!
    end

    Cronjob.clear_defunct_vpas!
  end

  private

  def each_cron_entry(add_jitter: true)
    `whenever`.each_line do |line|
      next if line.match?(/^\s*$/)
      next if line.match?(/^\s*#/)

      yield get_cron_expression(line, add_jitter: add_jitter), get_command(line)
    end
  end

  def get_cron_expression(line, add_jitter:)
    tokens = line.split(' ')

    (minute, hour, day_of_month, month, day_of_week) = tokens[0, 5]

    # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions
    if day_of_week.to_i.to_s == day_of_week && day_of_week.to_i < 7 # it's an integer and looks like a day
      # You can't specify the Day-of-month and Day-of-week fields in the same cron expression. If you specify a value (or a *) in one of the fields, you must use a ? (question mark) in the other.
      day_of_week = Date::ABBR_DAYNAMES[day_of_week.to_i].upcase
      day_of_month = '?'
    elsif day_of_month == '*' && day_of_week == '*'
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
          hour_correction = -1 * (Time.zone.now.utc_offset / 60.0 / 60.0).to_i

          ((h.to_i + hour_correction) % 24).to_s
        end.join(',')
      else
        hour
      end

    jitterize =
      if add_jitter
        ->(min, amount) do
          if min.to_i < 60 - amount
            min.to_i + Random.rand(amount)
          else
            min.to_i - Random.rand(amount)
          end
        end
      else
        ->(min, _amount) { min }
      end

    minute_with_jitter =
      case minute
      when /^\d+$/
        jitterize.call(minute, AMOUNT_OF_JITTER_IN_MINUTES)
      when /,/
        minute.
          split(',').
          each_cons(2).
          map { |val, nextone| jitterize.call(val, nextone.to_i - val.to_i) }.
          join(',')
      else
        raise 'Implement jitter for slash-based cron entries'
      end

    "#{minute_with_jitter} #{utc_hour} #{day_of_month} #{month} #{day_of_week}".tr('?', '*')
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

CronInstaller.new.run! if $PROGRAM_NAME.match?(/cron_installer/)
