# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Tasks are namespaced as driver:hmis_simulation:* by the driver loader.
# Usage examples:
#   bundle exec rake driver:hmis_simulation:validate[drivers/hmis_simulation/config/sample/small_coc.json]
#   bundle exec rake driver:hmis_simulation:setup_from_file[drivers/hmis_simulation/config/sample/small_coc.json]
#   bundle exec rake driver:hmis_simulation:run[hmis_simulation/demo-coc-small,2026-01-15]
#   bundle exec rake driver:hmis_simulation:run_range[hmis_simulation/demo-coc-small,2026-01-01,2026-01-31]
#   bundle exec rake driver:hmis_simulation:run_all
#
# Bootstrap runs automatically before the first run. The standalone bootstrap task
# is still available if you need to pre-create HUD records ahead of time:
#   bundle exec rake driver:hmis_simulation:bootstrap[hmis_simulation/demo-coc-small]

module HmisSimulationRake
  def self.print_simulation_summary(data_source_id)
    puts '— Data source totals ————————————————'
    {
      'Clients' => Hmis::Hud::Client,
      'CustomClientNames' => Hmis::Hud::CustomClientName,
      'Enrollments' => Hmis::Hud::Enrollment,
      'Exits' => Hmis::Hud::Exit,
      'Services' => Hmis::Hud::Service,
      'Disabilities' => Hmis::Hud::Disability,
      'IncomeBenefits' => Hmis::Hud::IncomeBenefit,
      'HealthAndDv' => Hmis::Hud::HealthAndDv,
      'EmploymentEducation' => Hmis::Hud::EmploymentEducation,
      'CurrentLivingSit.' => Hmis::Hud::CurrentLivingSituation,
      'Assessments' => Hmis::Hud::Assessment,
      'AssessmentResults' => Hmis::Hud::AssessmentResult,
      'Events' => Hmis::Hud::Event,
      'WarehouseClients' => GrdaWarehouse::WarehouseClient,
      'ServiceHistoryEnr.' => GrdaWarehouse::ServiceHistoryEnrollment,
    }.each do |label, klass|
      count = klass.where(data_source_id: data_source_id).count
      puts "  #{label.ljust(22)} #{count}" if count > 0
    end
    puts '—————————————————————————————————————'
  end

  def self.sync_simulation_warehouse(data_source_id, updated_since: nil)
    puts 'Syncing warehouse...'
    HmisSimulation::WarehouseSyncer.new(data_source_ids: data_source_id).call(updated_since: updated_since)
    puts 'Warehouse sync complete'
  end
end

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
  batch_start = Time.current
  HmisSimulation::Engine.new(config).run(date: date)
  HmisSimulationRake.sync_simulation_warehouse(config['data_source_id'].to_i, updated_since: batch_start)
  puts "Run complete for #{date}"
end

desc 'Run simulation for a date range (YYYY-MM-DD)'
task :run_range, [:key, :start_date, :end_date] => :environment do |_t, args|
  key        = args[:key]
  start_date = Date.parse(args[:start_date])
  end_date   = Date.parse(args[:end_date])
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:run_range[key,2026-01-01,2026-01-31]' if key.blank? || start_date.blank? || end_date.blank?

  config = HmisSimulation::ConfigLoader.from_app_config(key)
  engine = HmisSimulation::Engine.new(config)
  batch_start = Time.current
  (start_date..end_date).each do |date|
    engine.run(date: date)
    puts "  Completed #{date}"
  end
  HmisSimulationRake.sync_simulation_warehouse(config['data_source_id'].to_i, updated_since: batch_start)
  puts "Range complete: #{start_date} – #{end_date}"
  puts ''
  HmisSimulationRake.print_simulation_summary(config['data_source_id'].to_i)
end

desc 'Bootstrap HUD records (orgs, projects, ProjectCoc, Inventory, Funders) from an AppConfigProperty key'
task :bootstrap, [:key] => :environment do |_t, args|
  key = args[:key]
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:bootstrap[hmis_simulation/key]' if key.blank?

  config = HmisSimulation::ConfigLoader.from_app_config(key)
  HmisSimulation::Bootstrapper.new(config).run!
  puts "Bootstrap complete for #{config['name'].inspect} (data_source_id: #{config['data_source_id']})"
end

desc 'Audit generated data for a simulation against HUD compliance rules'
task :validate_data, [:key] => :environment do |_t, args|
  key = args[:key]
  raise ArgumentError, 'Usage: rake driver:hmis_simulation:validate_data[hmis_simulation/key]' if key.blank?

  config = HmisSimulation::ConfigLoader.from_app_config(key)
  data_source_id = config['data_source_id']

  validator = HmisSimulation::ComplianceValidator.new(data_source_id: data_source_id)
  violations = validator.validate!

  if violations.empty?
    puts "✓ No compliance violations found for data_source_id #{data_source_id}"
  else
    warn "✗ #{violations.size} compliance violation(s) found:"
    violations.group_by { |v| v[:type] }.each do |type, group|
      warn "  #{type} (#{group.size}):"
      group.first(5).each { |v| warn "    - #{v[:message]}" }
      warn "    ... and #{group.size - 5} more" if group.size > 5
    end
    exit 1
  end
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
  puts 'Bootstrap will run automatically on first run_all, run, or run_range.'
  puts "To bootstrap now: rake driver:hmis_simulation:bootstrap[#{key}]"
end
