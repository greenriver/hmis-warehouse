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
      GrdaWarehouse::Tasks::PushClientsToCas.new().sync!
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
      GrdaWarehouse::Tasks::ServiceHistory::Update.new.run!
      @notifier.ping('Service history generated') if @send_notifications
      Nickname.populate!
      @notifier.ping('Nicknames updated') if @send_notifications
      UniqueName.update!
      @notifier.ping('Unique names generated') if @send_notifications
      GrdaWarehouse::Tasks::CensusImport.new.run!
      @notifier.ping('Census imported') if @send_notifications
      GrdaWarehouse::Tasks::CensusAverages.new.run!
      @notifier.ping('Census averaged') if @send_notifications
      GrdaWarehouse::Tasks::EarliestResidentialService.new.run!
      @notifier.ping('Earliest residential services generated') if @send_notifications
      # Only run the chronic calculator on the 1st and 15th
      # but run it for the past 2 of each
      if Date.today.day.in?([1,15])
        this_month = Date.today.beginning_of_month
        last_month = this_month - 1.month
        if Date.today.day < 15
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
      # and then re-checks itself
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(1000).run!
      @notifier.ping('Sanity checked') if @send_notifications
      # Make sure we don't have anyone who needs re-generation, even if they have
      # birthdays that are incorrect
      GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
      @notifier.ping('Service history added') if @send_notifications
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

      if last_saturday_of_month(Date.today.month, Date.today.year) == Date.today
        @notifier.ping('Rebuilding Service History Indexes...') if @send_notifications
        @notifier.ping('(this could take a few hours, but only happens on the last Saturday of the month.)') if @send_notifications
        GrdaWarehouse::ServiceHistory.reindex_table!
        @notifier.ping('... Service History Indexes Rebuilt') if @send_notifications
      end

      @notifier.ping('Rebuilding reporting tables...') if @send_notifications
      GrdaWarehouse::Report::Base.update_fake_materialized_views
      @notifier.ping('...done rebuilding reporting tables') if @send_notifications

      @notifier.ping('Potentially queing confidence generation') if @send_notifications
      GrdaWarehouse::Confidence::DaysHomeless.queue_batch
      GrdaWarehouse::Confidence::SourceEnrollments.queue_batch
      GrdaWarehouse::Confidence::SourceExits.queue_batch

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
