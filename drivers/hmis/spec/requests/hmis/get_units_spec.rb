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

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:project) { create :hmis_hud_project, data_source: ds1 }
  let!(:template) { create :hmis_workflow_definition_template, status: 'published' }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetUnits(
        $id: ID!
        $limit: Int = 50
        $offset: Int = 0
        $filters: UnitFilterOptions
      ) {
        project(id: $id) {
          id
          units(limit: $limit, offset: $offset, filters: $filters) {
            nodesCount
            nodes {
              id
              latestOpportunity {
                id
                referral {
                  id
                  active
                }
              }
              acceptingCeReferrals
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'get units query' do
    context 'when the unit has no opportunity' do
      let!(:unit) { create(:hmis_unit, project: project) }

      it 'returns the unit without an opportunity' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'units', 'nodesCount')).to eq(1)
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity')).to be_nil
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
      end
    end

    context 'when the unit has an open opportunity' do
      let!(:unit) { create(:hmis_unit, project: project) }
      let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :open) }

      it 'returns the unit with the opportunity' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'units', 'nodesCount')).to eq(1)
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity')).to be_present
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_truthy
      end
    end

    context 'when the unit has an opportunity with a referral in progress' do
      let!(:unit) { create(:hmis_unit, project: project) }
      let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :locked) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, status: :in_progress) }

      it 'returns the unit with the opportunity and referral' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'units', 'nodesCount')).to eq(1)
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity')).to be_present
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'referral')).to be_present
      end
    end

    describe 'acceptingCeReferrals logic' do
      let!(:unit) { create(:hmis_unit, project: project) }

      context 'when the unit has no opportunities' do
        it 'acceptingCeReferrals is false' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity')).to be_nil
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
        end
      end

      context 'when the unit has an open opportunity' do
        let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :open) }

        it 'acceptingCeReferrals is true' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'id')).to eq(opportunity.id.to_s)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_truthy
        end
      end

      context 'when the unit has an opportunity with referrals in progress' do
        let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :locked) }
        let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, status: :in_progress) }

        it 'acceptingCeReferrals is false' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'id')).to eq(opportunity.id.to_s)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
        end
      end

      context 'when the unit has a closed opportunity, but no open one' do
        let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :closed) }
        let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, status: :accepted) }

        it 'acceptingCeReferrals is false' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'id')).to eq(opportunity.id.to_s)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
        end
      end
    end

    context 'when there are many units' do
      before do
        50.times do
          unit = create :hmis_unit, project: project
          opportunity = create(:hmis_ce_opportunity, owner: unit, project: project, status: :locked)
          create(:hmis_ce_referral, opportunity: opportunity, status: :in_progress)
        end
      end

      it 'avoids n+1 queries' do
        expect do
          response, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodesCount')).to eq(50)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'referral')).to be_present
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'referral', 'active')).to be_truthy
        end.to make_database_queries(count: 18..22)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
