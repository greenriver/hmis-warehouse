###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Nightly job that advances every configured simulation by one or more days.
  #
  # Finds all AppConfigProperty records whose key starts with "hmis_simulation/",
  # derives the start date from last_successful_run_date + 1, and runs the engine
  # forward through end_date (defaults to today).
  #
  # Each simulation is isolated — one failure writes an error RunLog entry but
  # does not prevent other simulations from running.
  #
  # After all simulations complete, queues warehouse service-history processing
  # so the new HUD records are immediately available in reports.
  #
  # Usage (manual):
  #   HmisSimulation::RunnerJob.perform_later
  #
  # Scheduled via: driver:hmis_simulation:run_all rake task (see schedule.rb)
  class RunnerJob < BaseJob
    include NotifierConfig

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    SIM_KEY_PREFIX = 'hmis_simulation/'

    def perform(end_date: Date.current)
      setup_notifier('HmisSimulation::RunnerJob')

      config_keys = AppConfigProperty.where('key LIKE ?', "#{SIM_KEY_PREFIX}%").pluck(:key)

      if config_keys.empty?
        log('No simulation configs found — nothing to run')
        return
      end

      log("Found #{config_keys.size} simulation config(s)")

      config_keys.each do |key|
        advance_simulation(key, end_date: end_date)
      end

      Hmis::Hud::Enrollment.queue_service_history_processing!
      log('Service history processing queued')
    end

    private

    def advance_simulation(key, end_date:)
      config = HmisSimulation::ConfigLoader.from_app_config(key)
      data_source_id = config['data_source_id'].to_i

      last_run = HmisSimulation::RunLog.last_successful_run_date(data_source_id)
      start_date = last_run ? last_run + 1 : end_date

      if start_date > end_date
        log("Simulation '#{config['name']}' is already current through #{last_run}")
        return
      end

      engine = HmisSimulation::Engine.new(config)
      failing_date = nil
      (start_date..end_date).each do |date|
        failing_date = date
        engine.run(date: date)
      end
      failing_date = nil

      days_run = (end_date - start_date).to_i + 1
      log("Simulation '#{config['name']}' advanced #{days_run} day(s) through #{end_date}")
    rescue StandardError => e
      record_simulation_error(config, failing_date || end_date, e)
    end

    def record_simulation_error(config, date, error)
      data_source_id = config['data_source_id'].to_i
      warn_msg = "Simulation '#{config['name']}' (data_source_id: #{data_source_id}) failed on #{date}: #{error.message}"
      log(warn_msg)
      Sentry.capture_exception(error) if defined?(Sentry)

      existing = HmisSimulation::RunLog.find_by(data_source_id: data_source_id, run_date: date)
      if existing
        existing.update!(error_message: error.message, finished_at: Time.current)
      else
        HmisSimulation::RunLog.create!(
          data_source_id: data_source_id,
          run_date: date,
          started_at: Time.current,
          finished_at: Time.current,
          error_message: error.message,
        )
      end
    rescue StandardError
      nil
    end

    def log(message)
      @notifier&.ping("[HmisSimulation] #{message}")
      Rails.logger.info("[HmisSimulation] #{message}")
    end
  end
end
