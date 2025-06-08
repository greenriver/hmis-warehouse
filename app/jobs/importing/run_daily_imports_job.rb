###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Importing
  class RunDailyImportsJob < BaseJob
    include ActionView::Helpers::DateHelper
    include NotifierConfig
    include ArelHelper
    include MaintenanceTaskInstrumentation

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize
      setup_notifier('Nightly Process')
      super
    end

    def perform
      with_lock do
        @start_time = Time.current
        settle_imports

        # first perform lifecycle events, generating alerts for missing jobs
        handle_maintenance_tasks_lifecycle
        # now run this jobs tasks
        _perform
        finish_processing
      end
    end

    protected

    def _perform
      run_maintenance_task('Revoke expired consent') do
        # expire client consent form if past 1 year
        GrdaWarehouse::Hud::Client.revoke_expired_consent
        @notifier.ping('Revoked expired client consent if appropriate')
      end

      if GrdaWarehouse::Config.get(:release_duration) == 'Use Expiration Date'
        # Update consent if it comes from HMIS Client
        run_maintenance_task('Maintain client consent') do
          GrdaWarehouse::HmisClient.maintain_client_consent
          @notifier.ping('Set client consent if appropriate')
        end
      end

      run_maintenance_task('Update from HMIS forms') do
        update_from_hmis_forms
      end
      run_maintenance_task('Sync with CAS') do
        sync_with_cas
      end

      run_maintenance_task('Identify Duplicates') do
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!
        GrdaWarehouse::ClientMatch.auto_process!
        @notifier.ping('Duplicates identified')
      end

      run_maintenance_task('Clean projects') do
        # this keeps the computed project type columns in sync, previously
        # this was done with a coalesce query, but it ended up being too slow
        # on large data operations, and any other project data cleanup
        GrdaWarehouse::Tasks::ProjectCleanup.new.run!
        @notifier.ping('Projects cleaned')
      end

      run_maintenance_task('Clean clients') do
        # This fixes any unused destination clients that can
        # bungle up the service history generation, among other things
        GrdaWarehouse::Tasks::ClientCleanup.new.run!
        @notifier.ping('Clients cleaned')
      end

      run_maintenance_task('Generate service history') do
        range = ::Filters::DateRange.new(start: 1.years.ago, end: Date.current)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_date_range!(range)
        # Make sure there are no unprocessed invalidated enrollments
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_unprocessed!
        @notifier.ping('Service history generated')
      end

      run_maintenance_task('Full sanity check') do
        # Fix anyone who received a new exit or entry added prior to the last year
        GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(client_ids: destination_client_ids).run!
        @notifier.ping('Full sanity check complete')
      end

      run_maintenance_task('Rebuild residential first dates') do
        # Rebuild residential first dates
        GrdaWarehouse::Tasks::EarliestResidentialService.new.run!
        @notifier.ping('Earliest residential services generated')
      end

      run_maintenance_task('Refreshing Service History Materialized View') do
        # Update the materialized view that we use to search by client_id and project_type
        @notifier.ping('Refreshing Service History Materialized View')
        GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
        GrdaWarehouse::ServiceHistoryServiceMaterialized.new.double_check_materialized_view(destination_client_ids.sample(500))
        @notifier.ping('Done Refreshing Service History Materialized View')
      end

      run_maintenance_task('Updating service history summaries') do
        # Maintain some summary data to speed up searches and history display and other things
        # To keep this manageable, we'll just deal with clients we've seen in the past year
        # When we sanity check and rebuild using the per-client method, this gets correctly maintained
        @notifier.ping('Updating service history summaries')
        GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts
        @notifier.ping('Updated service history summaries')
      end

      run_maintenance_task('Populate nicknames') do
        Nickname.populate!
        @notifier.ping('Nicknames updated')
      end

      run_maintenance_task('Generate unique names') do
        UniqueName.update!
        @notifier.ping('Unique names generated')
      end

      run_maintenance_task('Import Census') do
        GrdaWarehouse::Tasks::CensusImport.new.run!
        @notifier.ping('Census imported')
      end

      run_maintenance_task('Pre-calculate Chronically Homeless at Entry') do
        # Pre-calculate Chronically Homeless at Entry
        @notifier.ping('Pre-calculating Chronically Homeless at Entry')
        GrdaWarehouse::ChEnrollment.maintain!
        @notifier.ping('Done Pre-calculating Chronically Homeless at Entry')
      end

      run_maintenance_task('Calculate chronically homeless') do
        # Only run the chronic calculator on the 1st and 15th
        # but run it for the past 2 of each
        if @start_time.to_date.day.in?([1, 15])
          months_to_build = 6
          dates = []
          months_to_build.times do |i|
            dates << i.months.ago.change(day: 15).to_date
            dates << i.months.ago.change(day: 1).to_date
          end
          dates.select! { |m| m <= Date.current }

          dates.each do |date|
            GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: date).run!
            GrdaWarehouse::Tasks::DmhChronicallyHomeless.new(date: date).run!
            GrdaWarehouse::Tasks::HudChronicallyHomeless.new(date: date).run!
          end
          @notifier.ping('Chronically homeless calculated')
        end
      end

      run_maintenance_task('Clean clients') do
        GrdaWarehouse::Tasks::ClientCleanup.new.run!
        @notifier.ping('Clients cleaned (again)')
      end

      run_maintenance_task('Sanity check service history') do
        # The sanity check should always be last
        # It has the potential to run for a long time since it
        # self-heals the warehouse for anyone it finds that is broken
        # and then re-checks itself.
        # For now we are checking all destination clients.  This should catch any old
        # entries or exits that were added or removed.
        GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(client_ids: destination_client_ids).run!
        @notifier.ping('Sanity checked')
      end

      run_maintenance_task('Warm cache') do
        # pre-populate the cache for data source date spans
        # GrdaWarehouse::DataSource.data_spans_by_id()
        # @notifier.ping('Data source date spans set')

        warm_cache
      end

      run_maintenance_task('Reporting setup') do
        ReportingSetupJob.set(priority: 15).perform_later unless Delayed::Job.queued?('ReportingSetupJob')

        @notifier.ping('Rebuilding reporting tables...')
        GrdaWarehouse::Report::Base.update_fake_materialized_views
        @notifier.ping('...done rebuilding reporting tables')

        # Pre-calculate the dashboards (unless already queued)
        unless Delayed::Job.queued?('Reporting::PopulationDashboardPopulateJob')
          @notifier.ping('Updating dashboards')
          Reporting::PopulationDashboardPopulateJob.set(priority: 10).perform_later(sub_population: 'all')
        end
      end

      run_maintenance_task('System maintenance') do
        # Remove any expired export jobs
        PruneDocumentExportsJob.perform_later
        Health::PruneDocumentExportsJob.perform_later

        YouthFollowUpsJob.set(priority: 10).perform_later
        SystemCohortsJob.set(priority: 10).perform_later unless Delayed::Job.queued?('SystemCohortsJob')
        AccessGroup.delayed_system_group_maintenance
        Collection.delayed_system_group_maintenance
        GrdaWarehouse::Cohort.delay.maintain_auto_maintained!
        SyncSyntheticDataJob.perform_later if CasBase.db_exists?

        create_statistical_matches
        generate_logging_info
      end
    end

    def destination_client_ids
      @destination_client_ids ||= GrdaWarehouse::Hud::Client.destination.pluck(:id)
    end

    # Process ALL maintenance tasks, not just this job's tasks
    def handle_maintenance_tasks_lifecycle
      GrdaWarehouse::Tasks::SystemMaintenanceTask.find_each(&:process_alerts)

      # Clean up expired runs for ALL tasks
      GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.expired.delete_all
    end

    def run_maintenance_task(name, &block)
      instrument_as_maintenance_task(job: self, name: name) do |run|
        block.call
        run.record_success!
      end
    end

    def with_lock
      lock_name = 'run_daily_imports_job'
      did_run = false
      GrdaWarehouse::DataSource.with_advisory_lock(lock_name, timeout_seconds: 1) do
        yield
        did_run = true
      end
      return if did_run

      # refuse to run if there's already a nightly process running
      msg = 'Nightly process already running EXITING!!!'
      @notifier.ping(msg)
    end

    def settle_imports
      klass = GrdaWarehouse::DataSource
      4.times do
        #  break if no imports are active
        break if klass.importable.none? { |ds| klass.advisory_lock_exists?("hud_import_#{ds.id}") }

        sleep(60 * 5) # wait 5 minutes if we're importing, don't wait more than 20
      end
    end

    def last_saturday_of_month(month, year)
      end_of_month = Date.new(year, month, 1).end_of_month
      end_of_month.downto(0).find(&:saturday?)
    end

    def warm_cache
      GrdaWarehouse::DataSource.data_spans_by_id
    end

    def generate_logging_info
      return if GrdaWarehouse::Config.get(:multi_coc_installation)

      # take snapshots of client enrollments
      GrdaWarehouse::EnrollmentChangeHistory.generate_for_date!

      @notifier.ping('Potentially queuing confidence generation')
      GrdaWarehouse::Confidence::DaysHomeless.queue_batch
      GrdaWarehouse::Confidence::SourceEnrollments.queue_batch
      GrdaWarehouse::Confidence::SourceExits.queue_batch
    end

    def create_statistical_matches
      # Generate some duplicates if we need to, but not too many
      opts = {
        threshold: -1.45,
        batch_size: 10_000,
        run_length: 10,
      }
      SimilarityMetric::Tasks::GenerateCandidates.new(batch_size: opts[:batch_size], threshold: opts[:threshold], run_length: opts[:run_length]).run!
      @notifier.ping('New matches generated')
    end

    def finish_processing
      seconds = ((Time.current - @start_time) / 1.minute).round * 60
      run_time = distance_of_time_in_words(seconds)
      msg = "Nightly Process completed in #{run_time}"
      Rails.logger.tagged({ task_name: 'Nightly Process', repeating_task: true, task_runtime: Time.current - @start_time }) do
        @notifier.ping(msg)
      end
    end

    def update_from_hmis_forms
      if GrdaWarehouse::HmisForm.vispdat.exists?
        GrdaWarehouse::HmisForm.set_missing_vispdat_scores
        @notifier.ping('Set VI-SPDAT Scores from ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_missing_vispdat_pregnancies
        @notifier.ping('Set VI-SPDAT Pregnancies from ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_part_of_a_family
        @notifier.ping('Updated Family Status based on ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_missing_housing_status
        @notifier.ping('Set Housing Status based on ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_missing_physical_disabilities
        @notifier.ping('Set Physical Disabilities based on ETO TouchPoints')
      end

      # Maintain ETO based CAS flags
      GrdaWarehouse::Tasks::UpdateClientsFromHmisForms.new.run!

      GrdaWarehouse::HmisClient.maintain_client_consent
      @notifier.ping('Set client consent if appropriate')
    end

    def sync_with_cas
      return unless CasBase.db_exists?

      # Disable CAS for anyone who's been housed in CAS
      # NOTE: if a client is forced `sync_with_cas` and is successful on a match
      # and `sync_with_cas` is true at time of success, there's a potential
      # timing issue around when the warehouse knows of success.  If that happens
      # after this is called, the client will be made available for matching again and
      # all unavilable fors will be removed
      GrdaWarehouse::CasHoused.inactivate_clients

      GrdaWarehouse::Tasks::PushClientsToCas.new.sync!
      @notifier.ping('Pushed Clients to CAS')
    end
  end
end
