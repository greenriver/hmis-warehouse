###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisExternalApis::AcHmis::UpdateReferralPostingJob do
  describe 'create referral request' do
    include_context 'hmis base setup'

    let(:requested_by) do
      'text@example.com'
    end

    let!(:link_creds) do
      create(:ac_hmis_link_credential)
    end

    it 'has no smoke' do
      posting = create(:hmis_external_api_ac_hmis_referral_posting)
      accepted_status_code = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch(:accepted_status)

      result = HmisExternalApis::OauthClientResult.new(
        parsed_body: {
          'postings' => [
            'postingId' => posting.identifier,
            'postingStatusId' => accepted_status_code,
          ],
        },
      )
      expect_any_instance_of(HmisExternalApis::OauthClientConnection).to receive(:patch)
        .with(
          'Referral/PostingStatus',
          {
            'postingId' => posting.identifier,
            'postingStatusId' => accepted_status_code,
            'requestedBy' => requested_by,
          },
        )
        .and_return(result)

      HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
        posting_id: posting.identifier,
        posting_status_id: accepted_status_code,
        requested_by: requested_by,
      )
      posting.reload
      expect(posting.status).to(eq('accepted_status'))
    end
  end
end
