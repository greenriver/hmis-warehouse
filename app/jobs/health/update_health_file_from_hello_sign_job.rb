module Health
  class UpdateHealthFileFromHelloSignJob < ActiveJob::Base
    queue_as :low_priority

    def perform(signable_document_id)
      doc = Health::SignableDocument.un_fetched_document.where(id: signable_document_id)&.first
      return unless doc.present?
      Rails.logger.info("Processing health file for signable document #{doc.id}")
      doc.update_health_file_from_hello_sign
    end
  end
end
