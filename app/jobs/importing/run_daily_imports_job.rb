module Importing
  class RunDailyImportsJob < ActiveJob::Base
    include ActionView::Helpers::DateHelper
    include NotifierConfig
    include ArelHelper
    attr_accessor :send_notifications, :notifier_config
    queue_as :low_priority

    def initialize
      setup_notifier('DailyImporter')
    end

    def perform
      lock_checks = 4
      while active_imports? && lock_checks > 0
        sleep(60 * 5) # wait 5 minutes if we're importing, don't wait more than 20
        lock_checks -= 1
      end
      start_time = Time.now

      # expire client consent form if past 1 year
      GrdaWarehouse::Hud::Client.revoke_expired_consent
      @notifier.ping('Revoked expired client consent if appropriate') if @send_notifications

      GrdaWarehouse::Tasks::PushClientsToCas.new().sync!
      @notifier.ping('Pushed Clients to CAS') if @send_notifications

      # Importers::Samba.new.run!
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      @notifier.ping('Duplicates identified') if @send_notifications
      # this keeps the computed project type columns in sync, previously 
      # this was done with a coalesce query, but it ended up being too slow
      # on large data operations
      GrdaWarehouse::Tasks::CalculateProjectTypes.new.run!
      @notifier.ping('Project types calculated') if @send_notifications
      # Sometimes client data changes in such a way as to leave behind stub
      # clients with no enrollments, this clears those out.
      # GrdaWarehouse::Tasks::ClientCleanup.new.remove_clients_without_enrollments! unless active_imports?
      
      # This fixes any unused destination clients that can
      # bungle up the service history generation, among other things
      GrdaWarehouse::Tasks::ClientCleanup.new.run!
      @notifier.ping('Clients cleaned') if @send_notifications

      range = ::Filters::DateRange.new(start: 1.years.ago, end: Date.today)
      GrdaWarehouse::Hud::Enrollment.open_during_range(range).
        joins(:project, :destination_client).
        pluck_in_batches(:id, batch_size: 250) do |batch|
        Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch), queue: :low_priority)
      end
      # GrdaWarehouse::Tasks::ServiceHistory::Update.new.run!
      # Make sure we've finished processing the service history before we move on
      # Some of the later items require this to be finished to be correct.
      GrdaWarehouse::Tasks::ServiceHistory::Update.wait_for_processing
      @notifier.ping('Service history generated') if @send_notifications
      # Fix anyone who received a new exit or entry added prior to the last year
      dest_clients = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(dest_clients.size, dest_clients).run!
      @notifier.ping('Full sanity check complete') if @send_notifications
      GrdaWarehouse::Tasks::EarliestResidentialService.new.run!
      @notifier.ping('Earliest residential services generated') if @send_notifications
      
      # Maintain some summary data to speed up searches and history display and other things
      # To keep this manageable, we'll just deal with clients we've seen in the past year
      # When we sanity check and rebuild using the per-client method, this gets correctly maintained
      client_ids = GrdaWarehouse::Hud::Enrollment.open_during_range(range).
        joins(:project, :destination_client).distinct.pluck(c_t[:id].as('client_id').to_sql)
      client_ids.each do |id|
        GrdaWarehouse::Tasks::ServiceHistory::Base.new().mark_processed(id)
      end

      Nickname.populate!
      @notifier.ping('Nicknames updated') if @send_notifications
      UniqueName.update!
      @notifier.ping('Unique names generated') if @send_notifications

      GrdaWarehouse::Tasks::CensusImport.new.run!
      @notifier.ping('Census imported') if @send_notifications
      GrdaWarehouse::Tasks::CensusAverages.new.run!
      @notifier.ping('Census averaged') if @send_notifications
      
      # Only run the chronic calculator on the 1st and 15th
      # but run it for the past 2 of each
      if start_time.to_date.day.in?([1,15])
        this_month = start_time.to_date.beginning_of_month
        last_month = this_month - 1.month
        if start_time.to_date.day < 15
          two_months_ago = this_month - 2.months
          dates = [
            this_month,
            Date.new(last_month.year, last_month.month, 15),
            last_month,
            Date.new(two_months_ago.year, two_months_ago.month, 15),
          ]
        else
          dates = [
            Date.new(this_month.year, this_month.month, 15),
            this_month,
            Date.new(last_month.year, last_month.month, 15),
            last_month,
          ]
        end
        dates.each do |date|
          GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: date).run!
          GrdaWarehouse::Tasks::DmhChronicallyHomeless.new(date: date).run!
          GrdaWarehouse::Tasks::HudChronicallyHomeless.new(date: date).run!
        end
        @notifier.ping('Chronically homeless calculated') if @send_notifications
      end
      GrdaWarehouse::Tasks::ClientCleanup.new.run!
      @notifier.ping('Clients cleaned (again)') if @send_notifications

      # The sanity check should always be last
      # It has the potential to run for a long time since it 
      # self-heals the warehouse for anyone it finds that is broken
      # and then re-checks itself.
      # For now we are checking all destination clients.  This should catch any old 
      # entries or exits that were added or removed.
      dest_clients = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(dest_clients.size, dest_clients).run!
      @notifier.ping('Sanity checked') if @send_notifications
      
      # pre-populate the cache for data source date spans
      GrdaWarehouse::DataSource.data_spans_by_id()
      @notifier.ping('Data source date spans set') if @send_notifications

      Rails.cache.clear

      # Generate some duplicates if we need to, but not too many
      opts = {
        threshold: -1.45,
        batch_size: 10000,
        run_length: 10,
      }
      SimilarityMetric::Tasks::GenerateCandidates.new(batch_size: opts[:batch_size], threshold: opts[:threshold], run_length: opts[:run_length]).run!
      @notifier.ping('New matches generated') if @send_notifications

      if last_saturday_of_month(start_time.to_date.month, start_time.to_date.year) == start_time.to_date
        @notifier.ping('Rebuilding Service History Indexes...') if @send_notifications
        @notifier.ping('(this could take a few hours, but only happens on the last Saturday of the month.)') if @send_notifications
        GrdaWarehouse::ServiceHistory.reindex_table!
        @notifier.ping('... Service History Indexes Rebuilt') if @send_notifications
      end

      @notifier.ping('Rebuilding reporting tables...') if @send_notifications
      GrdaWarehouse::Report::Base.update_fake_materialized_views
      @notifier.ping('...done rebuilding reporting tables') if @send_notifications

      @notifier.ping('Potentially queuing confidence generation') if @send_notifications
      GrdaWarehouse::Confidence::DaysHomeless.queue_batch
      GrdaWarehouse::Confidence::SourceEnrollments.queue_batch
      GrdaWarehouse::Confidence::SourceExits.queue_batch

      # Pre-calculate the dashboards on the weekends
      if start_time.to_date.wday > 5
        @notifier.ping('Updating dashboards') if @send_notifications
        GrdaWarehouse::WarehouseReports::Dashboard::Base.sub_populations_by_type.each do |report_type, reports|
          reports.each do |sub_population, _|
            WarehouseReports::DashboardReportJob.perform_later(report_type.to_s, sub_population.to_s)
          end
        end
      end

      seconds = ((Time.now - start_time)/1.minute).round * 60
      run_time = distance_of_time_in_words(seconds)
      msg = "RunDailyImportsJob completed in #{run_time}"
      Rails.logger.info msg
      @notifier.ping(msg) if @send_notifications
      
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
  end
end
