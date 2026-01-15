# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing::HudZip
  class FetchAndImportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 15

    def perform(...)
      instrument_as_maintenance_task do |run|
        run.complete! if _perform(...)
      end
    end

    def supports_idempotent_retry?
      false
    end

    def _perform(klass:, options:)
      safe_klass = known_classes.detect { |m| klass == m }
      raise "Unknown import class: #{klass}; You must add it to the list of known classes in FetchAndImportJob" unless safe_klass.present?

      data_source_id = options[:data_source_id]
      lock_obtained = nil

      GrdaWarehouse::DataSource.with_advisory_lock(advisory_lock_name(data_source_id), timeout_seconds: 60) do
        safe_klass.constantize.new(**options).import!
        # To prevent re-running when called against the same files if run more than once in a day, yield true
        lock_obtained = true
      end

      requeue_at(Time.current + WAIT_MINUTES.minutes, "Import of Data Source: #{data_source_id} already running...re-queuing job for #{WAIT_MINUTES} minutes from now") unless lock_obtained
      lock_obtained
    end

    def known_classes
      [
        'Importers::HmisAutoMigrate::S3',
      ].freeze
    end

    private def advisory_lock_name(data_source_id)
      GrdaWarehouse::DataSource.import_advisory_lock_name(data_source_id)
    end
  end
end
