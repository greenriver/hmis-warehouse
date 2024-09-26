#!/usr/bin/env ruby

# This script is used to prevent booting of kubernetes pods before the database
# is ready

class DbTester
  attr_accessor :model

  def initialize(model)
    self.model = model
  end

  def run!
    can_connect?
    important_table?
    migrations?

    puts "Database checks passed for #{model}"
  end

  private

  def can_connect?
    puts "Attempting to connect with #{model}"
    num = model.connection.execute('select 2*3').values.flatten.first.to_i
    return unless num != 6

    puts 'Cannot connect to database. Trying again in 60 seconds.'
    sleep 60
    exit(1)
  end

  def important_table?
    puts "Attempting to select from a table that should exist with #{model}"
    return if model.connection.schema_migration.table_exists?

    puts 'schema_migrations does not exist. Trying again in 60 seconds.'
    sleep 60
    exit(1)
  end

  def migrations?
    puts "Checking migrations for #{model}"

    ups = 0
    downs = 0
    model.connection.migration_context.migrations_status.each do |status, _version, _name|
      ups += 1 if status == 'up'
      downs += 1 if status == 'down'
    end

    return if ups > 3 && downs == 0

    puts 'Less than 3 migrations up or a migration has not run yet. Trying again in 60 seconds.'

    sleep 60
    exit(1)
  end
end

# rake db:migrate:status:primary works sometimes? I'm confused.
DbTester.new(ApplicationRecord).run!
DbTester.new(GrdaWarehouseBase).run!
DbTester.new(ReportingBase).run!
DbTester.new(HealthBase).run!
