module Importing
  class RunDailyImportsJob < ActiveJob::Base
    include ActionView::Helpers::DateHelper
    attr_accessor :send_notifications, :notifier_config

    def initialize
      @notifier_config = Rails.application.config_for(:exception_notifier)['slack'] rescue nil
      @send_notifications = notifier_config.present? && ( Rails.env.development? || Rails.env.production? )
      if @send_notifications
        slack_url = notifier_config['webhook_url']
        channel   = notifier_config['channel']
        @notifier  = Slack::Notifier.new slack_url, channel: channel, username: 'DailyImporter'
      end
    end

    def perform
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
      # This fixes any unused destination clients that can
      # bungle up the service history generation, among other things
      GrdaWarehouse::Tasks::ClientCleanup.new.run!
      @notifier.ping('Clients cleaned') if @send_notifications
      GrdaWarehouse::Tasks::ServiceHistory::UpdateAddPatch.new.run!
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
        if Date.today.day == 1
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
      # Generate some duplicates if we need to, but not too many
      opts = {
        threshold: -1.45,
        batch_size: 10000,
        run_length: 10,
      }
      SimilarityMetric::Tasks::GenerateCandidates.new(batch_size: opts[:batch_size], threshold: opts[:threshold], run_length: opts[:run_length]).run!
      @notifier.ping('New matches generated') if @send_notifications
      seconds = ((Time.now - start_time)/1.minute).round * 60
      run_time = distance_of_time_in_words(seconds)
      msg = "RunDailyImportsJob completed in #{run_time}"
      Rails.logger.info msg
      @notifier.ping(msg) if @send_notifications
      
    end
  end
end