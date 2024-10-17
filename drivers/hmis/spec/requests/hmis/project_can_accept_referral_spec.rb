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
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end
  before(:each) do
    hmis_login(user)
  end

  let!(:source_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:access_control) { create_access_control(hmis_user, source_project) }
  let!(:source_enrollment) { create :hmis_hud_enrollment, client: c1, project: source_project, data_source: ds1 }

  let!(:destination_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:referral_instance) { create :hmis_form_instance, role: :REFERRAL, entity: destination_project }

  describe 'projectCanAcceptReferral query' do
    let(:project_can_accept_referral_query) do
      <<~GRAPHQL
        query GetProjectCanAcceptReferral($sourceEnrollmentId: ID!, $destinationProjectId: ID!) {
          projectCanAcceptReferral(sourceEnrollmentId:$sourceEnrollmentId, destinationProjectId:$destinationProjectId)
        }
      GRAPHQL
    end

    it 'raises an error when the destination project does not accept referrals' do
      expect_access_denied post_graphql(destination_project_id: source_project.id, source_enrollment_id: source_enrollment.id) { project_can_accept_referral_query }
    end

    it 'raises an error when the referral form instance exists, but definition is a draft' do
      create(:hmis_form_definition, role: :REFERRAL, identifier: 'bad-referral-form', status: :draft)
      create(:hmis_form_instance, role: :REFERRAL, entity: source_project, definition_identifier: 'bad-referral-form')

      expect_access_denied post_graphql(destination_project_id: source_project.id, source_enrollment_id: source_enrollment.id) { project_can_accept_referral_query }
    end

    it 'raises an error when the user does not have can_manage_outgoing_referrals permission for the source project' do
      remove_permissions(access_control, :can_manage_outgoing_referrals)
      create_access_control(hmis_user, p1) # even when they have permissions at some other project
      expect_access_denied post_graphql(destination_project_id: destination_project.id, source_enrollment_id: source_enrollment.id) { project_can_accept_referral_query }
    end

    it 'returns true when the client does not have an open enrollment at the destination project' do
      response, result = post_graphql(destination_project_id: destination_project.id, source_enrollment_id: source_enrollment.id) { project_can_accept_referral_query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'projectCanAcceptReferral')).to eq(true)
    end

    it 'returns false when the client has an open enrollment at the destination project' do
      create :hmis_hud_enrollment, client: c1, project: destination_project, data_source: ds1
      response, result = post_graphql(destination_project_id: destination_project.id, source_enrollment_id: source_enrollment.id) { project_can_accept_referral_query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'projectCanAcceptReferral')).to eq(false)
    end

    it 'returns true when the client has an exited enrollment at the destination project' do
      create :hmis_hud_enrollment, client: c1, project: destination_project, data_source: ds1, entry_date: 2.weeks.ago, exit_date: 1.week.ago
      response, result = post_graphql(destination_project_id: destination_project.id, source_enrollment_id: source_enrollment.id) { project_can_accept_referral_query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'projectCanAcceptReferral')).to eq(true)
    end
  end
end
