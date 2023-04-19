###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisExternalApis::VoidReferralRequestJob do
  describe 'create referral request' do
    include_context 'hmis base setup'

    let(:endpoint) do
      'http://example.com/'
    end

    it 'has no smoke' do
      referral_request = create(
        :hmis_external_api_referral_request,
        requested_by: hmis_user,
      )

      # not sure what the response to expect
      payload = {}
      stub_request(:post, endpoint).
        to_return(status: 200, body: payload.to_json)

      HmisExternalApis::VoidReferralRequestJob.perform_now(
        url: endpoint,
        referral_request: referral_request,
        voided_by: hmis_user,
      )
      referral_request.reload
      expect(referral_request.voided_by).to(eq(hmis_user))
    end
  end
end
