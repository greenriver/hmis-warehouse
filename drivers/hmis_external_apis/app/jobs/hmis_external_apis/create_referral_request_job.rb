###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# An HMIS User indicates that there is a vacancy in a program.
module HmisExternalApis
  class CreateReferralRequestJob < ApplicationJob
    # @param referral_request [HmisExternalApis::ReferralRequest]
    def perform(referral_request:, url:)
      # if it's persisted, the assumption is that it's already been sent
      raise if referral_request.persisted?

      response = post_referral_request(url, payload(referral_request))
      referral_request.identifier = response.fetch('referral_request_id')
      referral_request.save!
      referral_request
    end

    protected

    def post_referral_request(url, params)
      response = Faraday.post(url, params)
      JSON.parse(response.body)
    end

    def format_date(date)
      date.strftime('%Y/%m/%d')
    end

    # FIXME: not sure best to lookup mper ids... assuming they are external_ids that will already exist?
    def mper_id(record)
      mper_cred.external_ids.where(source: record).first!.value
    end

    def mper_cred
      @mper_cred ||= GrdaWarehouse::RemoteCredential.mper
    end

    def payload(record)
      project = record.project
      organization = project.organization
      unit_type = record.unit_type
      {
        requested_date: format_date(record.requested_on),
        provider_id: mper_id(organization),
        provider_name: organization.OrganizationName,
        project_id: mper_id(project),
        project_name: project.ProjectName,
        unit_type_id: mper_id(unit_type),
        unit_type_description: unit_type.description,
        estimated_date_needed: format_date(record.needed_by),
        requested_by: record.requestor_name,
        requestor_phone_number: record.requestor_phone,
        requestor_email: record.requestor_email,
      }
    end
  end
end
