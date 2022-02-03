###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class DeliverScheduledDocumentsJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def self.any_to_run?
      Health::ScheduledDocuments::Base.active.any?(&:check_hour)
    end

    def perform(user)
      scheduled_document_scope.each do |scheduled_document|
        next unless scheduled_document.check_hour
        next unless scheduled_document.should_be_delivered?
        next unless scheduled_document.deliver(user)

        scheduled_document.update(last_run_at: Time.current)
      end
    end

    private def scheduled_document_scope
      scheduled_document_source.active
    end

    private def scheduled_document_source
      Health::ScheduledDocuments::Base
    end
  end
end
