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

    context 'when querying by workflow template' do
      let!(:referral) { create(:hmis_ce_referral, workflow_template: workflow_template_1) }
      let!(:referral2) { create(:hmis_ce_referral, workflow_template: workflow_template_1) }
      let!(:referral3) { create(:hmis_ce_referral, workflow_template: workflow_template_2) }

      let(:variables) do
        {
          filters: {
            workflowTemplate: [workflow_template_1.id],
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
