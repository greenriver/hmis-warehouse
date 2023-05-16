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
      referral_request.identifier = response.parsed_body.fetch('referral_request_id')
      referral_request.save!
      referral_request
    end

    protected

    def format_date(date)
      date.strftime('%Y-%m-%d')
    end

    def payload(record)
      project = record.project
      organization = project.organization
      unit_type = record.unit_type
      {
        requested_date: format_date(record.requested_on),
        provider_id: mper.identify_source(organization),
        provider_name: organization.OrganizationName,
        project_id: mper.identify_source(project),
        project_name: project.ProjectName,
        unit_type_id: mper.identify_source(unit_type),
        unit_type_description: unit_type.description,
        estimated_date_needed: format_date(record.needed_by),
        requested_by: record.requestor_name,
        requestor_phone_number: record.requestor_phone,
        requestor_email: record.requestor_email,
      }
    end
  end
end
