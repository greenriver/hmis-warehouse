###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class RunDailyImportsJob < BaseJob
    include ActionView::Helpers::DateHelper
    include NotifierConfig
    include ArelHelper
    attr_accessor :send_notifications, :notifier_config

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize
      setup_notifier('DailyImporter')
      super
    end

    def advisory_lock_key
      'run_daily_imports_job'
    end

    def perform
      # refuse to run if there's already a nightly process running
      if GrdaWarehouse::DataSource.advisory_lock_exists?(advisory_lock_key)
        msg = 'Nightly process already running EXITING!!!'
        logger.warn msg
        @notifier.ping(msg) if @send_notifications
        return
      end
      GrdaWarehouse::DataSource.with_advisory_lock(advisory_lock_key) do
        lock_checks = 4
        while active_imports? && lock_checks.positive?
          sleep(60 * 5) # wait 5 minutes if we're importing, don't wait more than 20
          lock_checks -= 1
        end
        @start_time = Time.now

        # expire client consent form if past 1 year
        GrdaWarehouse::Hud::Client.revoke_expired_consent
        log_progress('Revoked expired client consent if appropriate')
        # Update consent if it comes from HMIS Client
        if GrdaWarehouse::Config.get(:release_duration) == 'Use Expiration Date'
          GrdaWarehouse::HmisClient.maintain_client_consent
          log_progress('Set client consent if appropriate')
        end

        update_from_hmis_forms
        sync_with_cas

        # Importers::Samba.new.run!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!
        GrdaWarehouse::ClientMatch.auto_process!
        log_progress('Duplicates identified')

        # We will need this twice
        dest_clients = GrdaWarehouse::Hud::Client.destination.pluck(:id)

        # this keeps the computed project type columns in sync, previously
        # this was done with a coalesce query, but it ended up being too slow
        # on large data operations, and any other project data cleanup
        GrdaWarehouse::Tasks::ProjectCleanup.new.run!
        log_progress('Projects cleaned')

        # This fixes any unused destination clients that can
        # bungle up the service history generation, among other things
        cleanup_weeks = ENV.fetch('CLIENT_CLEANUP_WEEKS') { 2 }.to_i
        GrdaWarehouse::Tasks::ClientCleanup.new(changed_client_date: cleanup_weeks.weeks.ago.to_date).run!
        log_progress('Clients cleaned')

        range = ::Filters::DateRange.new(start: 1.years.ago, end: Date.current)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_date_range!(range)
        # Make sure there are no unprocessed invalidated enrollments
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_unprocessed!

        log_progress('Service history generated')
        # Fix anyone who received a new exit or entry added prior to the last year
        GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(client_ids: dest_clients).run!
        log_progress('Full sanity check complete')
        # Rebuild residential first dates
        GrdaWarehouse::Tasks::EarliestResidentialService.new.run!
        log_progress('Earliest residential services generated')

        # Update the materialized view that we use to search by client_id and project_type
        log_progress('Refreshing Service History Materialized View')
        GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
        GrdaWarehouse::ServiceHistoryServiceMaterialized.new.double_check_materialized_view(dest_clients.sample(500))
        log_progress('Done Refreshing Service History Materialized View')

        # Maintain some summary data to speed up searches and history display and other things
        # To keep this manageable, we'll just deal with clients we've seen in the past year
        # When we sanity check and rebuild using the per-client method, this gets correctly maintained
        log_progress('Updating service history summaries')
        GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts

        log_progress('Updated service history summaries')

        Nickname.populate!
        log_progress('Nicknames updated')
        UniqueName.update!
        log_progress('Unique names generated')

        GrdaWarehouse::Tasks::CensusImport.new.run!
        log_progress('Census imported')

        # Pre-calculate Chronically Homeless at Entry
        log_progress('Pre-calculating Chronically Homeless at Entry')
        GrdaWarehouse::ChEnrollment.maintain!
        log_progress('Done Pre-calculating Chronically Homeless at Entry')

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
          log_progress('Chronically homeless calculated')
        end
        GrdaWarehouse::Tasks::ClientCleanup.new.run!
        log_progress('Clients cleaned (again)')

        # The sanity check should always be last
        # It has the potential to run for a long time since it
        # self-heals the warehouse for anyone it finds that is broken
        # and then re-checks itself.
        # For now we are checking all destination clients.  This should catch any old
        # entries or exits that were added or removed.
        GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(client_ids: dest_clients).run!
        log_progress('Sanity checked')

        # pre-populate the cache for data source date spans
        # GrdaWarehouse::DataSource.data_spans_by_id()
        # log_progress('Data source date spans set')

        Rails.cache.clear
        warm_cache

        ReportingSetupJob.set(priority: 15).perform_later

        log_progress('Rebuilding reporting tables...')
        GrdaWarehouse::Report::Base.update_fake_materialized_views
        log_progress('...done rebuilding reporting tables')

        # Pre-calculate the dashboards
        log_progress('Updating dashboards')
        Reporting::PopulationDashboardPopulateJob.set(priority: 10).perform_later(sub_population: 'all')

        # Remove any expired export jobs
        PruneDocumentExportsJob.perform_later
        Health::PruneDocumentExportsJob.perform_later

        YouthFollowUpsJob.set(priority: 10).perform_later
        SystemCohortsJob.set(priority: 10).perform_later
        SyncSyntheticDataJob.perform_later if CasBase.db_exists?

        create_statistical_matches
        generate_logging_info
      end
    end

    def active_imports?
      GrdaWarehouse::DataSource.importable.map do |ds|
        ds.class.advisory_lock_exists?("hud_import_#{ds.id}")
      end.include?(true)
    end

    def last_saturday_of_month(month, year)
      end_of_month = Date.new(year, month, 1).end_of_month
      end_of_month.downto(0).find(&:saturday?)
    end

    def warm_cache
      # re-set cache key for delayed job
      Rails.cache.write('deploy-dir', Delayed::Worker::Deployment.deployed_to)
      GrdaWarehouse::DataSource.data_spans_by_id
    end

    def generate_logging_info
      return if GrdaWarehouse::Config.get(:multi_coc_installation)

      # take snapshots of client enrollments
      GrdaWarehouse::EnrollmentChangeHistory.generate_for_date!

      log_progress('Potentially queuing confidence generation')
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
      log_progress('New matches generated')
    end

    def update_from_hmis_forms
      if GrdaWarehouse::HmisForm.vispdat.exists?
        GrdaWarehouse::HmisForm.set_missing_vispdat_scores
        log_progress('Set VI-SPDAT Scores from ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_missing_vispdat_pregnancies
        log_progress('Set VI-SPDAT Pregnancies from ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_part_of_a_family
        log_progress('Updated Family Status based on ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_missing_housing_status
        log_progress('Set Housing Status based on ETO TouchPoints')
        GrdaWarehouse::HmisForm.set_missing_physical_disabilities
        log_progress('Set Physical Disabilities based on ETO TouchPoints')
      end

      # Maintain ETO based CAS flags
      GrdaWarehouse::Tasks::UpdateClientsFromHmisForms.new.run!

      GrdaWarehouse::HmisClient.maintain_client_consent
      log_progress('Set client consent if appropriate')
    end

    def sync_with_cas
      return unless CasBase.db_exists?

      # Disable CAS for anyone who's been housed in CAS
      GrdaWarehouse::CasHoused.inactivate_clients

      GrdaWarehouse::Tasks::PushClientsToCas.new.sync!
      log_progress('Pushed Clients to CAS')
    end
  end
end
