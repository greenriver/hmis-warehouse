###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    let(:endpoint) do
      'http://example.com/'
    end

    it 'has no smoke' do
      referral_request = build(
        :hmis_external_api_ac_hmis_referral_request,
        requested_by: hmis_user, # defined in 'hmis_base_setup' context
      )

      # setup external ids
      mper.create_external_id(source: referral_request.unit_type, value: SecureRandom.uuid)

      payload = { referral_request_id: referral_request_id }
      stub_request(:post, endpoint).
        to_return(status: 200, body: payload.to_json)

      HmisExternalApis::AcHmis::CreateReferralRequestJob.perform_now(
        url: endpoint,
        referral_request: referral_request,
      )
      expect(referral_request.persisted?).to(eq(true))
    end
  end
end
