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
  let!(:source_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:destination_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:source_ac) { create_access_control(hmis_user, source_project) }
  let!(:destination_ac) { create_access_control(hmis_user, destination_project) }
  let!(:link_creds) do
    create(:ac_hmis_link_credential)
  end
  let!(:coc) { create :hud_project_coc, data_source: ds1, project_id: destination_project.project_id, state: 'MA' }
  let!(:source_enrollment) do
    create :hmis_hud_enrollment, data_source: ds1, project: source_project, client: c1, user: u1
  end
  let!(:referral) do
    create(:hmis_external_api_ac_hmis_referral, enrollment: source_enrollment)
  end
  let!(:household_member) { create :hmis_external_api_ac_hmis_referral_household_member, client: c1, referral: referral }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateReferralPosting($id: ID!, $input: ReferralPostingInput!) {
        updateReferralPosting(id: $id, input: $input) {
          record {
            id
            status
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'when a referral is denied' do
    let!(:posting) do
      create(:hmis_external_api_ac_hmis_referral_posting, identifier: nil, referral: referral, project: destination_project, status: 'denied_pending_status')
    end

    it 'should close enrollments' do
      input = {
        status: 'denied_status',
        statusNote: 'test',
        referralResult: 'UNSUCCESSFUL_REFERRAL_PROVIDER_REJECTED',
      }
      expect do
        response, result = post_graphql(id: posting.id, input: input) { mutation }
        expect(response.status).to eq 200
        errors = result.dig('data', 'updateReferralPosting', 'errors')
        expect(errors).to be_empty
      end.to change(Hmis::Hud::Enrollment.where(id: source_enrollment.id).exited, :count).by(1)
    end
  end

  describe 'with existing enrollment in the destination project' do
    let!(:posting) do
      create(:hmis_external_api_ac_hmis_referral_posting, identifier: nil, referral: referral, project: destination_project, status: 'assigned_status', unit_type: nil)
    end

    input = {
      status: 'accepted_pending_status',
      statusNote: 'test',
      referralResult: 'SUCCESSFUL_REFERRAL_CLIENT_ACCEPTED',
    }

    it 'should error' do
      enrollment = create(:hmis_hud_enrollment, data_source: ds1, client: c1, project: destination_project)
      response, result = post_graphql(id: posting.id, input: input) { mutation }
      expect(response.status).to eq(200), result.inspect
      errors = result.dig('data', 'updateReferralPosting', 'errors')
      expect(errors).not_to be_empty
      expect(errors.pluck('fullMessage')).to include(match(/#{c1.full_name} already has an open enrollment in this project \(entry date: #{enrollment.entry_date}\)/))
    end

    it 'should error when the enrollment is wip' do
      enrollment = create(:hmis_hud_wip_enrollment, data_source: ds1, client: c1, project: destination_project)
      response, result = post_graphql(id: posting.id, input: input) { mutation }
      expect(response.status).to eq(200), result.inspect
      errors = result.dig('data', 'updateReferralPosting', 'errors')
      expect(errors).not_to be_empty
      expect(errors.pluck('fullMessage')).to include(match(/#{c1.full_name} already has an open enrollment in this project \(entry date: #{enrollment.entry_date}\)/))
    end

    it 'should not error when the enrollment is closed' do
      create(:hmis_hud_enrollment, data_source: ds1, client: c1, project: destination_project, entry_date: 2.months.ago, exit_date: 2.weeks.ago)
      response, result = post_graphql(id: posting.id, input: input) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'updateReferralPosting', 'errors')).to be_empty
      expect(result.dig('data', 'updateReferralPosting', 'record', 'status')).to eq('accepted_pending_status')
    end
  end
end
