###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'net/sftp'

module MedicaidHmisInterchange
  class MedicaidIdLookupJob < ::BaseJob
    include NotifierConfig

    def perform(client_ids, test: false)
      soap = ::Health::Soap::MassHealth.new(test: test)
      return unless soap.configured?

      setup_notifier('MedicaidIdLookup')

      clients = ::GrdaWarehouse::Hud::Client.find(client_ids)
      inquiry = MedicaidHmisInterchange::Health::MedicaidIdInquiry.create(service_date: Date.current, clients: clients)
      edi_doc = inquiry.build_inquiry_file
      inquiry.save!

      begin
        result = soap.realtime_eligibility_inquiry_request(edi_doc: edi_doc)

        if result.success?
          reply = MedicaidHmisInterchange::Health::MedicaidIdResponse.create(
            medicaid_id_inquiry: inquiry,
            response: result.response,
          )
          reply.subscribers.each do |subscriber|
            client = ::GrdaWarehouse::Hud::Client.find(reply.TRN(subscriber))
            client = client.destination_client if client.source?
            client.build_external_health_id(identifier: reply.medicaid_id(subscriber))
          end
        end
      rescue StandardError => e
        msg = 'Error in MedicaidIdLookupJob'
        Rails.logger.error "#{msg}: #{e}"
        @notifier.ping(msg, { exception: e }) if @send_notifications
      end
    end
  end
end
