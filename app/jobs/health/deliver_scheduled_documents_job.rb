###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class DeliverScheduledDocumentsJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(user)
      scheduled_document_source.each do |scheduled_document|
        if scheduled_document.should_be_delivered?
          scheduled_document.update(last_delivered_at: Time.current) if scheduled_document.deliver(user)
        end
      end
    end

    private def scheduled_document_source
      Health::ScheduledDocuments::Base
    end
  end
end
