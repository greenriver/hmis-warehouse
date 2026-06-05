# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Tasks are namespaced as driver:hmis_simulation:* by the driver loader.
# Usage examples:
#   bundle exec rake driver:hmis_simulation:validate[config/simulations/samples/small_coc.json]
#   bundle exec rake driver:hmis_simulation:setup_from_file[config/simulations/samples/small_coc.json]
#   bundle exec rake driver:hmis_simulation:bootstrap[hmis_simulation/demo-coc]
#   bundle exec rake driver:hmis_simulation:run[hmis_simulation/demo-coc,2026-01-15]
#   bundle exec rake driver:hmis_simulation:run_range[hmis_simulation/demo-coc,2026-01-01,2026-01-31]

desc 'Validate a simulation config file or AppConfigProperty key'
task :validate, [:path_or_key] => :environment do |_t, args|
  path_or_key = args[:path_or_key]
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:validate[path/to/config.json or hmis_simulation/key]' if path_or_key.blank?

  config = if path_or_key.end_with?('.json')
    HmisSimulation::ConfigLoader.from_file(path_or_key)
  else
    HmisSimulation::ConfigLoader.from_app_config(path_or_key)
  end

  validator = HmisSimulation::ConfigValidator.new(config)
  if validator.valid?
    puts "✓ Config is valid: #{config['name'].inspect} (data_source_id: #{config['data_source_id']})"
  else
    warn "✗ Config has #{validator.errors.size} error(s):"
    validator.errors.each { |e| warn "  - #{e}" }
    exit 1
  end
end

desc 'Enqueue RunnerJob to advance all active simulations (called by cron via schedule.rb)'
task run_all: :environment do
  HmisSimulation::RunnerJob.perform_later
  puts 'HmisSimulation::RunnerJob enqueued'
end

desc 'Run simulation for a single date (YYYY-MM-DD)'
task :run, [:key, :date] => :environment do |_t, args|
  key = args[:key]
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:run[hmis_simulation/key,2026-01-15]' if key.blank?

  date   = Date.parse(args[:date])
  config = HmisSimulation::ConfigLoader.from_app_config(key)
  HmisSimulation::Engine.new(config).run(date: date)
  puts "Run complete for #{date}"
end

desc 'Run simulation for a date range (YYYY-MM-DD)'
task :run_range, [:key, :start_date, :end_date] => :environment do |_t, args|
  key        = args[:key]
  start_date = Date.parse(args[:start_date])
  end_date   = Date.parse(args[:end_date])
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:run_range[key,2026-01-01,2026-01-31]' if key.blank?

  config = HmisSimulation::ConfigLoader.from_app_config(key)
  engine = HmisSimulation::Engine.new(config)
  (start_date..end_date).each do |date|
    engine.run(date: date)
    puts "  Completed #{date}"
  end
  puts "Range complete: #{start_date} – #{end_date}"
end

desc 'Bootstrap HUD records (orgs, projects, ProjectCoc, Inventory, Funders) from an AppConfigProperty key'
task :bootstrap, [:key] => :environment do |_t, args|
  key = args[:key]
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:bootstrap[hmis_simulation/key]' if key.blank?

  config = HmisSimulation::ConfigLoader.from_app_config(key)
  HmisSimulation::Bootstrapper.new(config).run!
  puts "Bootstrap complete for #{config['name'].inspect} (data_source_id: #{config['data_source_id']})"
end

desc 'Load a simulation config JSON file into AppConfigProperty and validate it'
task :setup_from_file, [:path] => :environment do |_t, args|
  path = args[:path]
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:setup_from_file[path/to/config.json]' if path.blank?

  raw = HmisSimulation::ConfigLoader.from_file(path)
  validator = HmisSimulation::ConfigValidator.new(raw)
  unless validator.valid?
    warn 'Config has errors — fix before loading:'
    validator.errors.each { |e| warn "  - #{e}" }
    exit 1
  end

  key = "hmis_simulation/#{raw['name'].parameterize}"
  HmisSimulation::ConfigLoader.upsert_app_config(key, raw)
  puts "Saved config as AppConfigProperty key: #{key.inspect}"
  puts "Run bootstrap next: rake driver:hmis_simulation:bootstrap[#{key}]"
end
