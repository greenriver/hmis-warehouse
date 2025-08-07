# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  let!(:workflow_template_1) { create(:hmis_workflow_definition_template, identifier: 'wft_1', data_source: ds1) }
  let!(:workflow_template_2) { create(:hmis_workflow_definition_template, identifier: 'wft_2', data_source: ds1) }

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  describe 'admin ceReferrals query' do
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
              client {
                id
              }
              createdAt
              currentSteps {
                id
                name
              }
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

    it 'raises if the user does not have permission' do
      remove_permissions(access_control, :can_administrate_coordinated_entry)
      expect_gql_error(post_graphql { query }, message: 'access denied')
    end

    context 'when referrals have varying statuses' do
      let!(:referral) { create(:hmis_ce_referral, project: project, data_source: ds1, status: 'in_progress', updated_at: 1.month.ago) }
      let!(:referral_accepted) { create(:hmis_ce_referral, project: project, data_source: ds1, status: 'accepted', updated_at: 1.week.ago) }
      let!(:referral_rejected) { create(:hmis_ce_referral, project: project, data_source: ds1, status: 'rejected', updated_at: 1.day.ago) }

      it 'sorts referrals by status, then by date updated' do
        response, result = post_graphql { query }
        expect(response.status).to eq(200), result.inspect

        referrals = result.dig('data', 'ceReferrals', 'nodes')
        expect(referrals.map { |r| r['status'] }).to eq(['in_progress', 'rejected', 'accepted'])
      end

      it 'supports filtering referrals by status' do
        variables = { filters: { referralStatus: ['accepted'] } }
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        referrals = result.dig('data', 'ceReferrals', 'nodes')
        expect(referrals.size).to eq(1)
        expect(referrals.first['status']).to eq('accepted')
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
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        referrals = result.dig('data', 'ceReferrals', 'nodes')
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
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        referrals = result.dig('data', 'ceReferrals', 'nodes')
        expect(referrals.size).to eq(1)
        expect(referrals.dig(0, 'id')).to eq(referral.id.to_s)
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
        end.to make_database_queries(count: 30..40)

        # regression test to check that factories aren't creating extra data sources
        expect(GrdaWarehouse::DataSource.hmis.count).to eq(1)
      end
    end
  end
end
