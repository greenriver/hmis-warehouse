###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisExternalApis::AcHmis::VoidReferralRequestJob do
  describe 'create referral request' do
    include_context 'hmis base setup'

    let!(:link_creds) do
      create(:ac_hmis_link_credential)
    end

    it 'has no smoke' do
      referral_request = create(
        :hmis_external_api_ac_hmis_referral_request,
        requested_by: hmis_user,
      )
      result = HmisExternalApis::OauthClientResult.new(parsed_body: {})
      expect_any_instance_of(HmisExternalApis::OauthClientConnection).to receive(:patch)
        .with(
          "Referral/ReferralRequest/#{referral_request.identifier}",
          {
            'isVoid' => true,
            'requestedBy' => hmis_user.name,
          },
        )
        .and_return(result)

      HmisExternalApis::AcHmis::VoidReferralRequestJob.perform_now(
        referral_request: referral_request,
        user: hmis_user,
      )
      referral_request.reload
      expect(referral_request.voided_by).to(eq(hmis_user))
    end
  end
end
