###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Tasks
  class CheckPatientEligibility
    include NotifierConfig

    def initialize
      setup_notifier('Health Eligibility')
    end

    def check(eligibility_date, batch_size:, owner_id:, user: nil, test: false)
      patients = Health::EligibilityInquiry.patients.order(:id)
      offset = 0
      loop do
        batch = patients.limit(batch_size).offset(offset)
        break if batch.count == 0 # No more patients
        offset += batch_size

        inquiry = Health::EligibilityInquiry.create(service_date: eligibility_date, internal: true, batch: batch, batch_id: owner_id)
        edi_doc = inquiry.build_inquiry_file
        inquiry.save!

        soap = Health::Soap::MassHealth.new(test: test)
        return unless soap.configured?

        begin
          result = soap.realtime_eligibility_inquiry_request(edi_doc: edi_doc)

          if result.success?
            Health::EligibilityResponse.create(
              eligibility_inquiry: inquiry,
              response: result.response,
              user: user,
            )
            Health::FlagIneligiblePatientsJob.perform_later(inquiry.id)
          else
            Health::EligibilityResponse.create(
              eligibility_inquiry: inquiry,
              response: result.error_message,
              user: user,
            )
          end
        rescue StandardError => e
          msg = "Error communicating with MassHealth: #{e}"
          Rails.logger.error msg
          @notifier.ping msg if @send_notifications

          Health::EligibilityResponse.create(
            eligibility_inquiry: inquiry,
            response: msg,
            user: user,
          )
        end
      end
    end
  end
end
