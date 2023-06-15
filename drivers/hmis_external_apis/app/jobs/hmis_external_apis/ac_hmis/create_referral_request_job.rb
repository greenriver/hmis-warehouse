###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# An HMIS User indicates that there is a vacancy in a program.
module HmisExternalApis::AcHmis
  class CreateReferralRequestJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    # @param referral_request [HmisExternalApis::AcHmis::ReferralRequest]
    def perform(referral_request)
      # if it's persisted, the assumption is that it's already been sent
      raise if referral_request.persisted?

      response = link.create_referral_request(payload(referral_request))
      referral_request.identifier = response.parsed_body.fetch('referralRequestID')
      referral_request.save!
      referral_request
    end

    protected

    def payload(record)
      project = record.project
      unit_type = record.unit_type
      {
        requested_date: format_date(record.requested_on),
        program_id: project.project_id,
        unit_type_id: mper.identify_source(unit_type),
        estimated_date: format_date(record.needed_by),
        requested_by: record.requested_by.email,
        requestor_name: record.requestor_name,
        requestor_phone_number: record.requestor_phone,
        requestor_email: format_requested_by(record.requestor_email),
      }
    end
  end
end
