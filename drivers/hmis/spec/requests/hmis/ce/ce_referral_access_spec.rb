# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) { hmis_login(user) }

  let(:access_query) do
    <<~GRAPHQL
      query CeReferralAccess($id: ID!) {
        ceReferral(id: $id) {
          id
          access {
            canViewReferralDetails
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

  shared_examples 'expect ce referral access field' do |field, expected|
    it "sets #{field} to #{expected.inspect}" do
      expect(referral_access[field]).to eq(expected)
    end
  end

  describe 'CeReferral access fields' do
    describe 'canViewReferralDetails' do
      include_examples 'expect ce referral access field', 'canViewReferralDetails', true

      context 'when the user can only view the referral summary' do
        before { remove_permissions(ds_access_control, :can_view_referral_details) }
        let!(:source_project) { create(:hmis_hud_project, data_source: ds1, user: u1, project_name: 'Source Project') }
        let!(:source_enrollment) { create(:hmis_hud_enrollment, client: client, project: source_project, data_source: ds1) }
        before { referral.update!(source_enrollment: source_enrollment) }
        let!(:source_project_access_control) { create_access_control(hmis_user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals]) }

        include_examples 'expect ce referral access field', 'canViewReferralDetails', false
      end
    end

    describe 'canAssignReferralTasks' do
      include_examples 'expect ce referral access field', 'canAssignReferralTasks', false

      context 'when the user can assign referral tasks' do
        before { add_permissions(ds_access_control, :can_assign_referral_tasks) }

        include_examples 'expect ce referral access field', 'canAssignReferralTasks', true
      end
    end

    describe 'canViewSourceEnrollmentDetails' do
      context 'without a source enrollment on the referral' do
        include_examples 'expect ce referral access field', 'canViewSourceEnrollmentDetails', false
      end

      context 'with a source enrollment but the user cannot view enrollment details' do
        let!(:source_project) { create(:hmis_hud_project, data_source: ds1, user: u1, project_name: 'Source Project') }
        let!(:source_enrollment) { create(:hmis_hud_enrollment, client: client, project: source_project, data_source: ds1) }
        before { referral.update!(source_enrollment: source_enrollment) }

        context 'when the user cannot view enrollment details' do
          include_examples 'expect ce referral access field', 'canViewSourceEnrollmentDetails', false
        end

        context 'when the user can view enrollment details' do
          before { add_permissions(ds_access_control, :can_view_enrollment_details) }

          include_examples 'expect ce referral access field', 'canViewSourceEnrollmentDetails', true
        end
      end
    end

    describe 'canViewTargetProject' do
      context 'when the user can view the target project' do
        include_examples 'expect ce referral access field', 'canViewTargetProject', true
      end

      context 'when user sees the referral via own-referral assignment, without project view' do
        before do
          referral.workflow_engine.start_workflow!(user: hmis_user)
          remove_permissions(ds_access_control, :can_view_project)
          add_permissions(ds_access_control, :can_view_own_referrals)

          step = referral.workflow_engine.active_steps.first
          step.assignments.create!(user: hmis_user)
        end

        include_examples 'expect ce referral access field', 'canViewTargetProject', false
        include_examples 'expect ce referral access field', 'canViewReferralDetails', true
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

        include_examples 'expect ce referral access field', 'canCreateReferralNote', true
      end

      context 'when user can perform own referral tasks' do
        let!(:ds_access_control) do
          create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_perform_own_referral_tasks, :can_view_project])
        end

        context 'and user is not assigned' do
          include_examples 'expect ce referral access field', 'canCreateReferralNote', false
        end

        context 'and user is assigned' do
          before do
            referral.participants.create!(swimlane: case_manager_swimlane, user: hmis_user)
            referral.workflow_engine.assign_task!(referral.workflow_engine.active_steps.first)
          end

          include_examples 'expect ce referral access field', 'canCreateReferralNote', true
        end
      end

      context 'when user can only view referrals but cannot perform tasks' do
        let!(:ds_access_control) do
          create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_view_project])
        end

        include_examples 'expect ce referral access field', 'canCreateReferralNote', false
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
