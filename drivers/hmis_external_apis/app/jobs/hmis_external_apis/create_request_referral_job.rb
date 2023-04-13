###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# An HMIS User indicates that there is a vacancy in a program.
module HmisExternalApis
  class CreateReferralRequestJob < ApplicationJob
    # @param referral_request [HmisExternalApis::ReferralRequest]
    def perform(referral_request:)
      raise if referral_request.persisted?

      response = post_referral_request(payload(referral_request))
      project.external_referral_requests.create!(
        identifier: response.fetch('referral_request_id'),
        project: project,
      )
    end

    protected

    def post_referral_request(params)
      response = Faraday.post(url, params)
      JSON.parse(response.body)
    end

    def url
      # FIXME: endpoint TBD
      raise
    end

    def format_date(date)
      date.strftime('%Y/%m/%d')
    end

    def mper_id(record)
      mper_cred.external_ids.where(source: record).first!.value
    end

    def mper_cred
      @mper_cred ||= GrdaWarehouse::RemoteCredential.mper
    end

    def payload(record)
      project = record.provider
      organization = project.organization
      unit_type = record.unit_type
      {
        requested_date: format_date(record.requested_on),
        provider_id: mper_id(organization),
        provider_name: organization.name,
        project_id: mper_id(project),
        project_name: project.name,
        unit_type_id: mper_id(unit_type),
        unit_type_description: unit_type.description,
        estimated_date_needed: format_date(unit_type.needed_by),
        requested_by: record.requestor_name,
        requestor_phone_number: record.requestor_phone,
        requestor_email: record.requestor_email,
      }
    end
  end
end
