###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
  end

  let!(:source_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:access_control) { create_access_control(hmis_user, source_project) }
  let!(:source_enrollment) { create :hmis_hud_enrollment, client: c1, project: source_project, data_source: ds1 }

  let!(:destination_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:referral_instance) { create :hmis_form_instance, role: :REFERRAL, entity: destination_project }

  shared_examples 'returns true for project can accept referral' do
    it 'returns true' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'projectCanAcceptReferral')).to eq(true)
    end
  end

  shared_examples 'returns false for project can accept referral' do
    it 'returns false' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'projectCanAcceptReferral')).to eq(false)
    end
  end

  describe 'projectCanAcceptReferral query' do
    let(:query) do
      <<~GRAPHQL
        query GetProjectCanAcceptReferral($sourceEnrollmentId: ID!, $destinationProjectId: ID!, $referralMode: ReferralMode) {
          projectCanAcceptReferral(sourceEnrollmentId: $sourceEnrollmentId, destinationProjectId: $destinationProjectId, referralMode: $referralMode)
        }
      GRAPHQL
    end

    let(:variables) do
      {
        destination_project_id: destination_project.id,
        source_enrollment_id: source_enrollment.id,
      }
    end

    it 'raises an error when the destination project does not accept referrals' do
      expect_access_denied post_graphql(**variables.merge(destination_project_id: source_project.id)) { query }
    end

    it 'raises an error when the referral form instance exists, but definition is a draft' do
      create(:hmis_form_definition, role: :REFERRAL, identifier: 'bad-referral-form', status: :draft)
      create(:hmis_form_instance, role: :REFERRAL, entity: source_project, definition_identifier: 'bad-referral-form')

      expect_access_denied post_graphql(**variables.merge(destination_project_id: source_project.id)) { query }
    end

    it 'raises an error when the user does not have can_manage_outgoing_referrals permission for the source project' do
      remove_permissions(access_control, :can_manage_outgoing_referrals)
      create_access_control(hmis_user, p1) # even when they have permissions at some other project
      expect_access_denied post_graphql(**variables) { query }
    end

    context 'when the referral can be accepted (no conflicting enrollment)' do
      it_behaves_like 'returns true for project can accept referral'
    end

    context 'when the client has a conflicting open enrollment at the destination project' do
      let!(:conflicting_enrollment) { create(:hmis_hud_enrollment, client: c1, project: destination_project, data_source: ds1) }

      it_behaves_like 'returns false for project can accept referral'
    end

    context 'when the client has an exited enrollment at the destination project' do
      let!(:exited_enrollment) { create(:hmis_hud_enrollment, client: c1, project: destination_project, data_source: ds1, entry_date: 2.weeks.ago, exit_date: 1.week.ago) }

      it_behaves_like 'returns true for project can accept referral'
    end

    context 'when the referral mode is CE' do
      let!(:receiving_ce_config) { create(:hmis_project_ce_config, project: destination_project, receives_direct_referrals: true) }

      let(:variables) do
        {
          destination_project_id: destination_project.id,
          source_enrollment_id: source_enrollment.id,
          referral_mode: 'coordinated_entry',
        }
      end

      context 'when the referral can be accepted' do
        it_behaves_like 'returns true for project can accept referral'
      end

      context 'when the client has a conflicting open enrollment at the destination project' do
        let!(:conflicting_enrollment) { create(:hmis_hud_enrollment, client: c1, project: destination_project, data_source: ds1) }

        it_behaves_like 'returns false for project can accept referral'
      end

      context 'when client already has an in-progress referral at the destination project' do
        let!(:conflicting_referral) { create(:hmis_ce_referral, client: c1, project: destination_project, data_source: ds1, status: :in_progress) }

        it_behaves_like 'returns false for project can accept referral'
      end

      context 'when dest project does not accept ce referrals' do
        let!(:receiving_ce_config) { create(:hmis_project_ce_config, project: destination_project, receives_direct_referrals: false) }

        it 'raises an error' do
          expect_access_denied post_graphql(**variables) { query }
        end
      end
    end
  end
end
