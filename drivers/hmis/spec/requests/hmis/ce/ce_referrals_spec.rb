# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  let!(:workflow_template_1) { create(:hmis_workflow_definition_template, identifier: 'wft_1', data_source: ds1) }
  let!(:workflow_template_2) { create(:hmis_workflow_definition_template, identifier: 'wft_2', data_source: ds1) }

  let!(:ds_access_control) { create_access_control(hmis_user, ds1) }

  describe 'ceReferrals query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeReferrals($limit: Int = 25, $offset: Int = 0, $filters: CeReferralFilterOptions = null) {
          ceReferrals(limit: $limit, offset: $offset, filters: $filters) {
            offset
            limit
            nodesCount
            nodes {
              id
              status
              active
              clientId
              clientName
              client {
                id
              }
              createdAt
              referredBy {
                id
                name
              }
              targetProjectId
              targetProjectName
              targetProjectType
              targetEnrollment {
                id
              }
              targetOrganizationName
              daysOnCurrentSteps
              currentSteps {
                id
                name
              }
              updatedBy {
                id
                name
              }
              opportunity {
                id
                name
                unit {
                  id
                  name
                }
              }
            }
          }
        }
      GRAPHQL
    end

    def perform_referrals_query(**variables)
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'ceReferrals', 'nodes')
    end

    context 'without permission' do
      let!(:ds_access_control) { create_access_control(hmis_user, ds1, without_permission: [:can_administrate_coordinated_entry, :can_view_referrals, :can_view_own_referrals, :can_view_outgoing_referral_details]) }

      it 'returns no referrals' do
        expect(perform_referrals_query).to be_empty
      end
    end

    context 'with limited permissions' do
      let!(:ds_access_control) { create_access_control(hmis_user, ds1, without_permission: [:can_administrate_coordinated_entry, :can_view_referrals, :can_view_own_referrals, :can_view_outgoing_referral_details]) }
      let!(:project2) { create :hmis_hud_project, data_source: ds1 }
      let!(:referral2) { create(:hmis_ce_referral, project: project2, data_source: ds1) }
      let!(:p1_access_control) { create_access_control(hmis_user, project) } # full permission in project

      it 'returns only referrals the user has permission to view' do
        referrals = perform_referrals_query
        expect(referrals.size).to eq(1)
        expect(referrals.sole['id']).to eq(referral.id.to_s) # can't see referral2 without permission in project
      end
    end

    context 'when referrals have varying statuses' do
      let!(:referral) { create(:hmis_ce_referral, project: project, data_source: ds1, status: 'in_progress', updated_at: 1.month.ago) }
      let!(:referral_accepted) { create(:hmis_ce_referral, project: project, data_source: ds1, status: 'accepted', updated_at: 1.week.ago) }
      let!(:referral_rejected) { create(:hmis_ce_referral, project: project, data_source: ds1, status: 'rejected', updated_at: 1.day.ago) }

      it 'sorts referrals by status, then by date updated' do
        referrals = perform_referrals_query
        expect(referrals.map { |r| r['status'] }).to eq(['in_progress', 'rejected', 'accepted'])
      end

      it 'supports filtering referrals by status' do
        variables = { filters: { referralStatus: ['accepted'] } }
        referrals = perform_referrals_query(**variables)
        expect(referrals.size).to eq(1)
        expect(referrals.first['status']).to eq('accepted')
      end
    end

    context 'when filtering by assigned to current user' do
      let!(:other_user) { create(:hmis_user, data_source: ds1) }
      let!(:referral_assigned_to_me) { create(:hmis_ce_referral, project: project, data_source: ds1) }
      let!(:referral_assigned_to_other) { create(:hmis_ce_referral, project: project, data_source: ds1) }
      let!(:referral_with_completed_step) { create(:hmis_ce_referral, project: project, data_source: ds1) }

      before do
        create(:hmis_wfe_step, instance: referral_assigned_to_me.workflow_instance, assignees: [hmis_user])
        create(:hmis_wfe_step, instance: referral_assigned_to_other.workflow_instance, assignees: [other_user])
        create(:hmis_wfe_step, instance: referral_with_completed_step.workflow_instance, assignees: [hmis_user], status: 'completed')
      end

      it 'returns only referrals with an open step assigned to the current user' do
        referrals = perform_referrals_query(filters: { assignedToYou: true })
        expect(referrals.map { |r| r['id'] }).to contain_exactly(referral_assigned_to_me.id.to_s)
      end
    end

    context 'when querying by workflow template' do
      let!(:referral) { create(:hmis_ce_referral, project: project, data_source: ds1, workflow_template: workflow_template_1) }
      let!(:referral2) { create(:hmis_ce_referral, project: project, data_source: ds1, workflow_template: workflow_template_1) }
      let!(:referral3) { create(:hmis_ce_referral, project: project, data_source: ds1, workflow_template: workflow_template_2) }

      let(:variables) do
        {
          filters: {
            workflowTemplate: [workflow_template_1.identifier],
          },
        }
      end

      it 'returns only referrals with that workflow template' do
        referrals = perform_referrals_query(**variables)
        expect(referrals.size).to eq(2)
        expect(referrals.map { |r| r['id'] }).to contain_exactly(referral.id.to_s, referral2.id.to_s)
      end
    end

    context 'when querying by time on current step' do
      let!(:referral) { create(:hmis_ce_referral, project: project, data_source: ds1, workflow_template: workflow_template) }
      let!(:referral2) { create(:hmis_ce_referral, project: project, data_source: ds1, workflow_template: workflow_template) }
      let!(:referral3) { create(:hmis_ce_referral, project: project, data_source: ds1, workflow_template: workflow_template) }

      let!(:simultaneous_task) { create(:hmis_workflow_definition_user_task, template: workflow_template, name: 'Simultaneous task') }

      before do
        # Set up a parallel task, so that we can test multiple current steps
        start_event.connect_to!(simultaneous_task)

        referral.workflow_engine.start_workflow!(user: hmis_user)
        step = referral.steps
        step.update_all(available_at: 4.days.ago) # fake time on the current steps so they show up in the filter

        referral2.workflow_engine.start_workflow!(user: hmis_user)
        referral3.workflow_engine.start_workflow!(user: hmis_user)
      end

      let(:variables) do
        {
          filters: {
            onCurrentTaskSince: 3.days.ago,
          },
        }
      end

      it 'filters correctly' do
        referrals = perform_referrals_query(**variables)
        expect(referrals.size).to eq(1)
        expect(referrals.dig(0, 'id')).to eq(referral.id.to_s)
      end
    end

    context 'when querying referrals by organization' do
      let!(:project2) { create :hmis_hud_project, data_source: ds1, user: u1 }
      let!(:referral2) { create(:hmis_ce_referral, project: project2, data_source: ds1) }

      let(:variables) do
        {
          filters: {
            organization: [project.organization.id],
          },
        }
      end

      it 'filters correctly' do
        referrals = perform_referrals_query(**variables)
        expect(referrals.size).to eq(1)
        expect(referrals.dig(0, 'id')).to eq(referral.id.to_s) # referral2 is excluded
      end
    end

    context 'when searching referrals by client name' do
      let!(:client1) { create(:hmis_hud_client, data_source: ds1, FirstName: 'Alice', LastName: 'Wonderland') }
      let!(:client2) { create(:hmis_hud_client, data_source: ds1, FirstName: 'Bob', LastName: 'Builder') }
      let!(:referral1) { create(:hmis_ce_referral, project: project, data_source: ds1, client: client1) }
      let!(:referral2) { create(:hmis_ce_referral, project: project, data_source: ds1, client: client2) }

      it 'can search by client name' do
        variables = { filters: { searchTerm: 'Wonderland' } }
        referrals = perform_referrals_query(**variables)
        expect(referrals.size).to eq(1)
        expect(referrals.first['id']).to eq(referral1.id.to_s)
      end

      it 'can search by referral ID' do
        variables = { filters: { searchTerm: referral2.id.to_s } }
        referrals = perform_referrals_query(**variables)
        expect(referrals.size).to eq(1)
        expect(referrals.first['id']).to eq(referral2.id.to_s)
      end
    end

    context 'when referral has available script task' do
      # Regression test: Ensures ScriptTasks don't appear in currentSteps (only User tasks should be resolved).
      # This came up after a manual support fix left a dangling available script task. Also future-proofing for other task types.
      let!(:referral) { create(:hmis_ce_referral, project: project, data_source: ds1, workflow_template: workflow_template_1) }
      let!(:script_task) { create(:hmis_workflow_definition_script_task, template: workflow_template_1, name: 'Script Task') }
      let!(:start_event) { create(:hmis_workflow_definition_start_event, template: workflow_template_1) }
      let!(:script_step) do
        # Manually create an available script task step to simulate a dangling step from a manual support fix
        referral.workflow_instance.steps.create!(
          node: script_task,
          status: 'available',
          available_at: Time.current,
        )
      end

      before do
        referral.workflow_engine.start_workflow!(user: hmis_user) # start workflow to make user task available
      end

      it 'does not include ScriptTask in currentSteps, only UserTask' do
        referrals = perform_referrals_query
        expect(referrals).to contain_exactly(a_hash_including('currentSteps' => [a_hash_including('name' => 'Client Acceptance')]))
      end
    end

    context 'with many referrals' do
      before do
        create_list(:hmis_ce_referral, 40, project: project, data_source: ds1)
      end

      it 'queries the db a reasonable amount' do
        expect do
          response, result = post_graphql { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceReferrals', 'nodesCount')).to eq(41)
        end.to make_database_queries(count: 35..50)

        # regression test to check that factories aren't creating extra data sources
        expect(GrdaWarehouse::DataSource.hmis.count).to eq(1)
      end
    end
  end
end
