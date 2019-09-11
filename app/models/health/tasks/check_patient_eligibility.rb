###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::Tasks
  class CheckPatientEligibility

    def check(eligibility_date, test: false)
      inquiry = Health::EligibilityInquiry.create(service_date: eligibility_date)
      edi_doc = inquiry.build_inquiry_file
      inquiry.save!

      soap = Health::Soap::MassHealth.new(test: test)
      result = soap.realtime_eligibility_inquiry_request(edi_doc: edi_doc)

      if result.success?
        Health::EligibilityResponse.create(eligibility_inquiry: inquiry,
          response: result.response,
          user: 0 #TODO
        )
        Health::FlagIneligiblePatientsJob.perform_later(inquiry.id)
      else
        # TODO report error
        result.error_message
      end
    end
  end
end