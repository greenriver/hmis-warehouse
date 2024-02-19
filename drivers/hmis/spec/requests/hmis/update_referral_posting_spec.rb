###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:access_control) { create_access_control(hmis_user, p2) }
  let!(:link_creds) do
    create(:ac_hmis_link_credential)
  end
  let!(:e1) do
    create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1
  end
  let(:referral) do
    create(:hmis_external_api_ac_hmis_referral, enrollment: e1)
  end
  let(:referral_posting) do
    create(:hmis_external_api_ac_hmis_referral_posting, identifier: nil, referral: referral, project: p2, status: 'denied_pending_status')
  end

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateReferralPosting($id: ID!, $input: ReferralPostingInput!) {
        updateReferralPosting(id: $id, input: $input) {
          record {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should close enrollments on denial' do
    input = {
      status: 'denied_status',
      statusNote: 'test',
      referralResult: 'UNSUCCESSFUL_REFERRAL_PROVIDER_REJECTED',
    }
    expect do
      response, result = post_graphql(id: referral_posting.id, input: input) { mutation }
      expect(response.status).to eq 200
      errors = result.dig('data', 'updateReferralPosting', 'errors')
      expect(errors).to be_empty
    end.to change(Hmis::Hud::Enrollment.where(id: e1.id).exited, :count).by(1)
  end
end
