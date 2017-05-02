module Importing
  class RunDailyImportsJob < ActiveJob::Base
    include ActionView::Helpers::DateHelper
    attr_accessor :send_notifications, :notifier_config

    def initialize
      @notifier_config = Rails.application.config_for(:exception_notifier) rescue nil
      @send_notifications = notifier_config && ( Rails.env.development? || Rails.env.production? )
    end

    def perform
      start_time = Time.now
      GrdaWarehouse::Tasks::PushClientsToCas.new().sync!
      Importers::Samba.new.run!
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      # This fixes any unused destination clients that can
      # bungle up the service history generation, among other things
      GrdaWarehouse::Tasks::ClientCleanup.new.run!
      GrdaWarehouse::Tasks::GenerateServiceHistory.new.run!
      Nickname.populate!
      UniqueName.update!
      GrdaWarehouse::Tasks::CensusImport.new.run!
      GrdaWarehouse::Tasks::CensusAverages.new.run!
      GrdaWarehouse::Tasks::EarliestResidentialService.new.run!
      # Only run the chronic calculator on the 1st and 15th
      if Date.today.day.in?([1,15])
        GrdaWarehouse::Tasks::ChronicallyHomeless.new.run!
        GrdaWarehouse::Tasks::DmhChronicallyHomeless.new.run!
      end
      GrdaWarehouse::Tasks::ClientCleanup.new.run!

      # The sanity check should always be last
      # It has the potential to run for a long time since it 
      # self-heals the warehouse for anyone it finds that is broken
      # and then re-checks itself
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(1000).run!

      # Generate some duplicates if we need to, but not too many
      opts = {
        threshold: -1.45,
        batch_size: 10000,
        run_length: 10,
      }
      SimilarityMetric::Tasks::GenerateCandidates.new(batch_size: opts[:batch_size], threshold: opts[:threshold], run_length: opts[:run_length]).run!

      seconds = ((Time.now - start_time)/1.minute).round * 60
      run_time = distance_of_time_in_words(seconds)
      msg = "RunDailyImportsJob completed in #{run_time}"
      Rails.logger.info msg
      if send_notifications
        slack_url = notifier_config['slack']['webhook_url']
        channel   = notifier_config['slack']['channel']
        notifier  = Slack::Notifier.new slack_url, channel: channel, username: 'DailyImporter'
        notifier.ping msg
      end
    end
  end
end