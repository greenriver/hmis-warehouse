# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) { hmis_login(user) }

  let(:access_query) do
    # Resolve all access fields except canViewReferralDetails, which will always be true when fetching a single referral by ID.
    # See project_outgoing_ce_referrals_spec.rb for detailed spec of that access field.
    <<~GRAPHQL
      query CeReferralAccess($id: ID!) {
        ceReferral(id: $id) {
          id
          access {
            canAssignReferralTasks
            canViewSourceEnrollmentDetails
            canViewTargetProject
            canCreateReferralNote
          }
        }
      }
    GRAPHQL
  end

  let!(:ds_access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [:can_view_clients, :can_view_project, :can_view_referrals],
    )
  end

  let(:variables) { { id: referral.id } }

  def referral_access
    response, result = post_graphql(**variables) { access_query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceReferral', 'access')
  end

  describe 'CeReferral access fields' do
    describe 'canAssignReferralTasks' do
      it 'returns false' do
        expect(referral_access['canAssignReferralTasks']).to be false
      end

      context 'when the user can assign referral tasks' do
        before { add_permissions(ds_access_control, :can_assign_referral_tasks) }

        it 'returns true' do
          expect(referral_access['canAssignReferralTasks']).to be true
        end
      end
    end

    describe 'canViewSourceEnrollmentDetails' do
      context 'without a source enrollment on the referral' do
        it 'returns false' do
          expect(referral_access['canViewSourceEnrollmentDetails']).to be false
        end
      end

      context 'with a source enrollment but the user cannot view enrollment details' do
        let!(:source_project) { create(:hmis_hud_project, data_source: ds1, user: u1, project_name: 'Source Project') }
        let!(:source_enrollment) { create(:hmis_hud_enrollment, client: client, project: source_project, data_source: ds1) }
        before { referral.update!(source_enrollment: source_enrollment) }

        context 'when the user cannot view enrollment details' do
          it 'returns false' do
            expect(referral_access['canViewSourceEnrollmentDetails']).to be false
          end
        end

        context 'when the user can view enrollment details' do
          before { add_permissions(ds_access_control, :can_view_enrollment_details) }

          it 'returns true' do
            expect(referral_access['canViewSourceEnrollmentDetails']).to be true
          end
        end
      end
    end

    describe 'canViewTargetProject' do
      context 'when the user can view the target project' do
        it 'returns true' do
          expect(referral_access['canViewTargetProject']).to be true
        end
      end

      context 'when user sees the referral via own-referral assignment, without project view' do
        before do
          referral.workflow_engine.start_workflow!(user: hmis_user)
          remove_permissions(ds_access_control, :can_view_project)
          add_permissions(ds_access_control, :can_view_own_referrals)

          step = referral.workflow_engine.active_steps.first
          step.assignments.create!(user: hmis_user)
        end

        it 'returns false' do
          expect(referral_access['canViewTargetProject']).to be false
        end
      end
    end

    describe 'canCreateReferralNote' do
      before do
        referral.workflow_engine.start_workflow!(user: hmis_user)
      end

      context 'when user can perform any referral tasks' do
        let!(:ds_access_control) do
          create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_perform_any_referral_tasks, :can_view_project])
        end

        it 'returns true' do
          expect(referral_access['canCreateReferralNote']).to be true
        end
      end

      context 'when user can perform own referral tasks' do
        let!(:ds_access_control) do
          create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_perform_own_referral_tasks, :can_view_project])
        end

        context 'and user is not assigned' do
          it 'returns false' do
            expect(referral_access['canCreateReferralNote']).to be false
          end
        end

        context 'and user is assigned' do
          before do
            referral.participants.create!(swimlane: case_manager_swimlane, user: hmis_user)
            referral.workflow_engine.assign_task!(referral.workflow_engine.active_steps.first)
          end

          it 'returns true' do
            expect(referral_access['canCreateReferralNote']).to be true
          end
        end
      end

      context 'when user can only view referrals but cannot perform tasks' do
        let!(:ds_access_control) do
          create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_view_project])
        end

        it 'returns false' do
          expect(referral_access['canCreateReferralNote']).to be false
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
