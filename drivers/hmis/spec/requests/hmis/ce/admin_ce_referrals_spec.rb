# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  let!(:workflow_template_1) { create(:hmis_workflow_definition_template, identifier: 'wft_1') }
  let!(:workflow_template_2) { create(:hmis_workflow_definition_template, identifier: 'wft_2') }

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
              currentStepTime
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

    context 'when querying by time on current step' do
      let!(:referral) { create(:hmis_ce_referral, workflow_template: workflow_template) }
      let!(:referral2) { create(:hmis_ce_referral, workflow_template: workflow_template) }
      let!(:referral3) { create(:hmis_ce_referral, workflow_template: workflow_template) }

      let!(:simultaneous_task) { create(:hmis_workflow_definition_task, template: workflow_template, name: 'Simultaneous task') }

      before do
        # Set up a parallel task, so that we can test multiple current steps
        start_event.connect_to!(simultaneous_task)

        referral.workflow_engine.start_workflow!(user: hmis_user)
        step = referral.steps
        step.update_all(updated_at: 4.days.ago) # fake time on the current steps so they show up in the filter

        referral2.workflow_engine.start_workflow!(user: hmis_user)
        referral3.workflow_engine.start_workflow!(user: hmis_user)
      end

      let(:variables) do
        {
          filters: {
            onCurrentStepSince: 3.days.ago,
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
        40.times do
          create(:hmis_ce_referral)
        end
      end

      it 'queries the db a reasonable amount' do
        expect do
          response, result = post_graphql { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceReferrals', 'nodesCount')).to eq(41)
        end.to make_database_queries(count: 15..25)
      end
    end
  end
end
