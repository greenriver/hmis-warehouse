###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class UpdateHealthFileFromHelloSignJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(signable_document_id)
      doc = Health::SignableDocument.un_fetched_document.where(id: signable_document_id)&.first
      return unless doc.present?

      Rails.logger.info("Processing health file for signable document #{doc.id}")
      doc.update_health_file_from_hello_sign
    end
  end
end
