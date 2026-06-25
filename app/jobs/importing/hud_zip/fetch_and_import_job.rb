###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Importing::HudZip
  # @see docs/features/hmis-csv-importer.md
  class FetchAndImportJob < BaseJob
    # Gracefully handle a worker whose ambient AWS creds are dead: requeue once for a
    # healthy worker (no burned attempt) and recycle the pod, then surface if persistent.
    include AwsCredentialRescue

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
        # If the worker's ambient AWS creds are dead, with_aws_credential_rescue requeues a
        # fresh attempt (bounded) and stops the worker rather than failing this job.
        with_aws_credential_rescue(wait: WAIT_MINUTES.minutes, context: "data source #{data_source_id}") do
          safe_klass.constantize.new(**options).import!
        end
        # To prevent re-running when called against the same files if run more than once in a day, yield true.
        # In the credential-failure case this also lets the original job row complete cleanly (instead of
        # failing/retrying) while exactly one fresh attempt stays scheduled — same contract as a lock collision.
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
