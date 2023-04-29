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

    let(:mper) do
      create(:ac_hmis_mper_credential)
      ::HmisExternalApis::AcHmis::Mper.new
    end

    let(:endpoint) do
      'http://example.com/'
    end

    it 'has no smoke' do
      posting = create(:hmis_external_api_ac_hmis_referral_posting)

      # setup external ids
      [
        posting.project,
        posting.project.organization,
      ].each do |record|
        mper.create_external_id(source: record, value: SecureRandom.uuid)
      end

      accepted_status_code = HmisExternalApis::AcHmis::ReferralPosting.statuses.fetch(:accepted_status)
      payload = { postings: [
        posting_id: posting.identifier,
        posting_status: accepted_status_code,
      ] }
      stub_request(:post, endpoint).
        to_return(status: 200, body: payload.to_json)

      HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
        url: endpoint,
        identifier: posting.id,
        status: accepted_status_code,
      )
      posting.reload
      expect(posting.status).to(eq('accepted_status'))
    end
  end
end
