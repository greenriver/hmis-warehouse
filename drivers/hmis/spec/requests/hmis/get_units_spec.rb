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
              unitGroup {
                name
              }
              latestOpportunity {
                id
                referral {
                  id
                  active
                }
              }
              acceptingCeReferrals
              deletable
              canBeMarkedAvailable
              canBeMarkedAvailableToday
              canBeMarkedUnavailable
              workflowTemplateName
              eligibilityRequirements {
                id
                name
                expression
              }
              priorityScheme {
                id
                name
                expression
              }
              prioritySchemes {
                id
                name
                expression
              }
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'get units query' do
    # needed to access the referral
    before { allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true) }

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
      let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: :open) }

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
      let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: :locked) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: :in_progress) }

      it 'returns the unit with the opportunity and referral' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'units', 'nodesCount')).to eq(1)
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity')).to be_present
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'referral')).to be_present
      end
    end

    context 'when the unit belongs to a unit group' do
      let!(:unit) { create(:hmis_unit_in_group, project: project) }

      it 'returns the unit with its group name' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'units', 'nodesCount')).to eq(1)
        expect(result.dig('data', 'project', 'units', 'nodes', 0, 'unitGroup', 'name')).to eq(unit.unit_group.name)
      end
    end

    describe 'acceptingCeReferrals logic' do
      let!(:unit) { create(:hmis_unit_in_group, project: project) }
      before(:each) do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
      end

      context 'when the unit has no opportunities' do
        it 'acceptingCeReferrals is false' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity')).to be_nil
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'deletable')).to be_truthy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedAvailable')).to be_truthy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedUnavailable')).to be_falsy
        end
      end

      context 'when the unit has an open opportunity' do
        let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: :open) }

        it 'acceptingCeReferrals is true' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'id')).to eq(opportunity.id.to_s)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_truthy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'deletable')).to be_truthy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedAvailable')).to be_falsy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedUnavailable')).to be_truthy
        end
      end

      context 'when the unit has an opportunity with referrals in progress' do
        let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: :locked) }
        let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: :in_progress) }

        it 'acceptingCeReferrals is false' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'id')).to eq(opportunity.id.to_s)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'deletable')).to be_falsy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedAvailable')).to be_falsy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedUnavailable')).to be_falsy
        end
      end

      context 'when the unit has a closed opportunity, but no open one' do
        let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: :closed) }
        let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: :accepted) }

        it 'acceptingCeReferrals is false' do
          _, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'id')).to eq(opportunity.id.to_s)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'acceptingCeReferrals')).to be_falsy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'deletable')).to be_truthy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedAvailable')).to be_truthy
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'canBeMarkedUnavailable')).to be_falsy
        end
      end
    end

    context 'when there are many units' do
      before do
        50.times do
          unit = create :hmis_unit, project: project
          opportunity = create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: :locked)
          create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: :in_progress)
        end
      end

      it 'avoids n+1 queries' do
        expect do
          response, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'units', 'nodesCount')).to eq(50)
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'referral')).to be_present
          expect(result.dig('data', 'project', 'units', 'nodes', 0, 'latestOpportunity', 'referral', 'active')).to be_truthy
        end.to make_database_queries(count: 25..35)
      end
    end

    describe 'CE match rules' do
      let!(:template) { create :hmis_workflow_definition_template, status: 'published', data_source: project.data_source }
      let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: template) }
      let!(:unit) { create(:hmis_unit, project: project, unit_group: unit_group) }

      before(:each) do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
      end

      context 'when unit has no rules' do
        it 'does not return eligibility requirements or priority scheme' do
          _, result = post_graphql(id: project.id) { query }
          unit_node = result.dig('data', 'project', 'units', 'nodes', 0)

          expect(unit_node['eligibilityRequirements']).to be_empty
          expect(unit_node['priorityScheme']).to be_nil
          expect(unit_node['prioritySchemes']).to be_empty
        end
      end

      context 'when unit group has current rules' do
        let!(:eligibility_rule) { create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'current_age >= 18', name: 'Age Requirement') }
        let!(:priority_rule) { create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'days_homeless', name: 'Homeless Priority') }

        it 'returns current unit group rules' do
          _, result = post_graphql(id: project.id) { query }
          unit_node = result.dig('data', 'project', 'units', 'nodes', 0)

          eligibility_requirements = unit_node['eligibilityRequirements']
          expect(eligibility_requirements).to be_an(Array)
          expect(eligibility_requirements.size).to eq(1)
          expect(eligibility_requirements[0]).to include(
            'name' => 'Age Requirement',
            'expression' => 'current_age >= 18',
          )

          priority_scheme = unit_node['priorityScheme']
          expect(priority_scheme).to include(
            'name' => 'Homeless Priority',
            'expression' => 'days_homeless',
          )

          expect(unit_node['prioritySchemes'].map { |r| r['expression'] }).to eq(['days_homeless'])
        end
      end

      context 'when unit has a stale opportunity with historical rules' do
        let!(:eligibility_rule) { create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'current_age >= 18', name: 'Age Requirement') }
        let!(:priority_rule) { create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'days_homeless', name: 'Homeless Priority') }

        let!(:opportunity) do
          create(:hmis_ce_opportunity,
                 unit: unit,
                 project: project,
                 data_source: ds1,
                 status: :open,
                 stale: true,
                 assignment_rules: [
                   {
                     'id' => 999,
                     'name' => 'Historical Age Rule',
                     'rule_type' => 'eligibility_requirement',
                     'expression' => 'current_age >= 21',
                   },
                   {
                     'id' => 998,
                     'name' => 'Historical Priority Rule',
                     'rule_type' => 'priority_scheme',
                     'expression' => 'chronic_days',
                   },
                 ])
        end

        it 'returns historical rules from the stale opportunity' do
          _, result = post_graphql(id: project.id) { query }
          unit_node = result.dig('data', 'project', 'units', 'nodes', 0)

          eligibility_requirements = unit_node['eligibilityRequirements']
          expect(eligibility_requirements).to be_an(Array)
          expect(eligibility_requirements.size).to eq(1)
          expect(eligibility_requirements[0]).to include(
            'name' => 'Historical Age Rule',
            'expression' => 'current_age >= 21',
          )
          # Ensure the GraphQL ID is modified to prevent cache conflicts
          expect(eligibility_requirements[0]['id']).to match(/^#{unit.id}\.999$/)

          priority_scheme = unit_node['priorityScheme']
          expect(priority_scheme).to include(
            'name' => 'Historical Priority Rule',
            'expression' => 'chronic_days',
          )
          expect(priority_scheme['id']).to match(/^#{unit.id}\.998$/)

          expect(unit_node['prioritySchemes'].map { |r| r['expression'] }).to eq(['chronic_days'])
        end
      end

      context 'when unit has no unit group' do
        let!(:unit_without_group) { create(:hmis_unit, project: project, unit_group: nil) }

        it 'does not return eligibility requirements or priority scheme' do
          _, result = post_graphql(id: project.id) { query }

          # Find the unit without a group
          unit_node = result.dig('data', 'project', 'units', 'nodes').find { |node| node['unitGroup'].nil? }
          expect(unit_node).to be_present

          expect(unit_node['eligibilityRequirements']).to be_empty
          expect(unit_node['priorityScheme']).to be_nil
        end
      end

      context 'when unit group has mixed-level priority schemes' do
        let!(:unit) { create(:hmis_unit, project: project, unit_group: unit_group) }
        let!(:org_rule) { create(:hmis_ce_priority_scheme, owner: project.organization, expression: 'org_expr', name: 'Org', priority_rank: 2) }
        let!(:ds_rule) { create(:hmis_ce_priority_scheme, owner: project.data_source, expression: 'ds_expr', name: 'DS', priority_rank: 1) }
        let!(:proj_rule_b) { create(:hmis_ce_priority_scheme, owner: project, expression: 'b', name: 'B', priority_rank: 2) }
        let!(:proj_rule_a) { create(:hmis_ce_priority_scheme, owner: project, expression: 'a', name: 'A', priority_rank: 1) }

        it 'returns only most-specific (project) rules ordered by priority_rank then id' do
          _, result = post_graphql(id: project.id) { query }
          unit_node = result.dig('data', 'project', 'units', 'nodes', 0)
          expect(unit_node['prioritySchemes'].map { |r| r['expression'] }).to eq(['a', 'b'])
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
