#!/usr/bin/env ruby
# frozen_string_literal: true

# This script is used to prevent booting of kubernetes pods before the database
# is ready

# The script seems to be freezing with no output. This might help debug it.
$stdout.sync = true

require 'timeout'

class DbTester
  attr_accessor :model, :start_time

  GIVE_UP_AFTER_SEC = 3600
  SLEEP_TIME_SEC = 60

  def initialize(model)
    self.model = model
    self.start_time = Time.current
  end

  def run!
    can_connect?
    important_table?
    migrations?

    puts "Database checks passed for #{model}"
  end

  private

  def can_connect?
    loop do
      puts "Attempting to connect with #{model}"

      begin
        puts 'Executing test query...'
        result = Timeout.timeout(30) do
          model.connection.execute('select 2*3')
        end
        puts 'Query executed successfully, processing result...'

        num = result.values.flatten.first.to_i
        puts "Query result: #{num}"
        return if num == 6
      rescue Timeout::Error
        puts 'Database query timed out after 30 seconds'
      rescue StandardError => e
        puts "Database connection error: #{e.class}: #{e.message}"
      end

      puts "Cannot connect to database. Trying again in #{SLEEP_TIME_SEC} seconds."
      sleep_or_exit
    end
  end

  def important_table?
    loop do
      puts "Attempting to select from a table that should exist with #{model}"

      begin
        result = Timeout.timeout(30) do
          model.connection.table_exists?(:schema_migrations)
        end
        puts "Table existence check completed: #{result}"
        return if result
      rescue Timeout::Error
        puts 'Table existence check timed out after 30 seconds'
      rescue StandardError => e
        puts "Error checking table existence: #{e.class}: #{e.message}"
      end

      puts "schema_migrations does not exist. Trying again in #{SLEEP_TIME_SEC} seconds."
      sleep_or_exit
    end
  end

  def migrations?
    loop do
      puts "Checking migrations for #{model}"

      begin
        ups = 0
        downs = 0

        migration_status = Timeout.timeout(30) do
          model.connection_pool.migration_context.migrations_status
        end
        puts "Migration status fetched, processing #{migration_status.length} migrations..."

        migration_status.each do |status, _version, _name|
          ups += 1 if status == 'up'
          downs += 1 if status == 'down'
        end

        puts "Migration summary: #{ups} up, #{downs} down"
        return if ups > 3 && downs == 0
      rescue Timeout::Error
        puts 'Migration status check timed out after 30 seconds'
      rescue StandardError => e
        puts "Error checking migration status: #{e.class}: #{e.message}"
      end

      puts "Less than 3 migrations up or a migration has not run yet. Trying again in #{SLEEP_TIME_SEC} seconds."

      sleep_or_exit
    end
  end

  def sleep_or_exit
    exit(1) if (Time.current - start_time) > GIVE_UP_AFTER_SEC
    sleep SLEEP_TIME_SEC
  end
end

# rake db:migrate:status:primary works sometimes? I'm confused.
DbTester.new(ApplicationRecord).run!
DbTester.new(GrdaWarehouseBase).run!
DbTester.new(ReportingBase).run!
DbTester.new(HealthBase).run!
