###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisExternalApis::AcHmis::CreateReferralRequestJob do
  describe 'create referral request' do
    include_context 'hmis base setup'

    let(:mper) do
      create(:ac_hmis_mper_credential)
      ::HmisExternalApis::AcHmis::Mper.new
    end

    let(:referral_request_id) do
      SecureRandom.uuid
    end

    let!(:link_creds) do
      create(:ac_hmis_link_credential)
    end

    it 'has no smoke' do
      referral_request = build(
        :hmis_external_api_ac_hmis_referral_request,
        requested_by: hmis_user, # defined in 'hmis_base_setup' context
      )
      # setup external ids
      unit_type_mper_id = SecureRandom.uuid
      mper.create_external_id(source: referral_request.unit_type, value: unit_type_mper_id)
      # Turn off the MPER integration before testing to ensure that all actions work
      # as expected even if the MPER credential is inactive. MPER integration is being deprecated
      # while LINK Referral integrations remain active for a while longer. See #8143 / #8142
      mper.send(:remote_credential).update!(active: false)

      result = HmisExternalApis::ExternalApiResult.new(
        parsed_body: { 'referralRequestID' => referral_request_id },
      )
      expect_any_instance_of(HmisExternalApis::OauthClientConnection).to receive(:post).
        with(
          'Referral/ReferralRequest',
          {
            'estimatedDate' => referral_request.needed_by.strftime('%Y-%m-%d'),
            'programID' => referral_request.project.ProjectID,
            'requestedBy' => hmis_user.email,
            'requestedDate' => referral_request.requested_on.iso8601,
            'requestorEmail' => referral_request.requestor_email,
            'requestorName' => referral_request.requestor_name,
            'requestorPhoneNumber' => referral_request.requestor_phone,
            'unitTypeID' => unit_type_mper_id,
          },
        ).
        and_return(result)

      HmisExternalApis::AcHmis::CreateReferralRequestJob.perform_now(referral_request)
      expect(referral_request.persisted?).to(eq(true))
      expect(referral_request.identifier).to(eq(referral_request_id))
    end
  end
end
