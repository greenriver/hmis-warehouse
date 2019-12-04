###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Tasks
  class CheckPatientEligibility
    def check(eligibility_date, batch_size:, user: nil, test: false)
      patients = Health::EligibilityInquiry.patients.order(:id)
      offset = 0
      loop do
        batch = patients.limit(batch_size).offset(offset)
        break if batch.count == 0 # No more patients
        offset += batch_size

        inquiry = Health::EligibilityInquiry.create(service_date: eligibility_date, internal: true, batch: batch)
        edi_doc = inquiry.build_inquiry_file
        inquiry.save!

        soap = Health::Soap::MassHealth.new(test: test)
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
      end
    end
  end
end