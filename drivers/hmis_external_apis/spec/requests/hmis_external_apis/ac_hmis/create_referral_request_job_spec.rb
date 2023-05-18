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

    let!(:link_creds) do
      create(:ac_hmis_link_credential)
    end

    before(:each) do
      result = HmisExternalApis::OauthClientResult.new(
        parsed_body: { referralRequestID: referral_request_id }.stringify_keys,
      )
      allow_any_instance_of(HmisExternalApis::AcHmis::LinkApi).to receive(:create_referral_request).and_return(result)
    end

    it 'has no smoke' do
      referral_request = build(
        :hmis_external_api_ac_hmis_referral_request,
        requested_by: hmis_user, # defined in 'hmis_base_setup' context
      )
      # setup external ids
      mper.create_external_id(source: referral_request.unit_type, value: SecureRandom.uuid)

      HmisExternalApis::AcHmis::CreateReferralRequestJob.perform_now(referral_request)
      expect(referral_request.persisted?).to(eq(true))
    end
  end
end
