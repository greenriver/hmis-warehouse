###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::Ce::MarkUnitsAvailable, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:project) { create :hmis_hud_project, data_source: ds1 }
  let!(:template) { create :hmis_workflow_definition_template, status: 'published', data_source: ds1 }
  let!(:unit_type) { create :hmis_unit_type, description: '1 Bedroom Apartment' }
  let!(:unit_group) { create :hmis_unit_group, project: project, workflow_template: template }
  let!(:unit) { create :hmis_unit, project: project, unit_type: unit_type, unit_group: unit_group }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  describe 'mark unit available mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation MarkUnitsAvailable($unitIds: [ID!]!) {
          markUnitsAvailable(unitIds: $unitIds) {
            units {
              #{scalar_fields(Types::HmisSchema::Unit)}
              latestOpportunity {
                id
                name
                eligibilityRequirements {
                  id
                  expression
                }
                priorityScheme {
                  id
                  expression
                }
              }
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    let(:variables) do
      { unitIds: [unit.id] }
    end

    context 'with valid input' do
      let!(:pool) { create(:hmis_ce_match_candidate_pool) }

      before do
        # In the new model, the unit group must have an assigned pool before marking available
        unit_group.update!(candidate_pool: pool)
      end

      it 'creates a new opportunity and marks the pool as dirty' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsAvailable', 'units', 0, 'latestOpportunity', 'name')).to include(unit.id.to_s)
        end.to change(Hmis::Ce::Opportunity, :count).by(1).and(
          change { pool.change_marker.reload.dirty? }.from(false).to(true),
        )

        unit.reload
        expect(unit.latest_opportunity.candidate_pool).to eq(pool)
        expect(unit.latest_opportunity.workflow_template).to eq(template)
      end

      it 'acquires a shared advisory lock' do
        lock_name = Hmis::Ce::Match::CandidatePoolBuilder.name.demodulize
        expect(GrdaWarehouseBase).to receive(:with_advisory_lock).
          with(lock_name, timeout_seconds: 3, shared: true).
          and_call_original

        post_graphql(**variables) { mutation }
      end

      context 'with assignment rules' do
        let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'current_age >= 18') }

        it 'captures assignment rules for historical reference' do
          # Run the builder to ensure the unit group gets a pool based on the rule
          Hmis::Ce::Match::CandidatePoolBuilder.call
          unit_group.reload

          _response, result = post_graphql(**variables) { mutation }

          opportunity = unit.reload.latest_opportunity
          requirements = result.dig('data', 'markUnitsAvailable', 'units', 0, 'latestOpportunity', 'eligibilityRequirements')
          expect(requirements).to be_present
          expect(requirements.first['id']).to include(rule.id.to_s) # GraphQL ID is a composite
          expect(requirements.first['expression']).to eq(rule.expression)

          # Verify the data was persisted correctly on the model
          expect(opportunity.assignment_rules.first['id']).to eq(rule.id)
        end
      end
    end

    context 'when unit is not in a unit group' do
      before do
        unit.update!(unit_group: nil)
      end

      it 'raises an error' do
        expect do
          expect_gql_error(
            post_graphql(**variables) { mutation },
            message: 'Unit must be in a Unit Group to be marked available',
          )
        end.to not_change(Hmis::Ce::Opportunity, :count)
      end
    end

    context 'when unit group has no candidate pool' do
      it 'raises an error' do
        expect do
          expect_gql_error(
            post_graphql(**variables) { mutation },
            message: 'Unit Group has no Candidate Pool',
          )
        end.to not_change(Hmis::Ce::Opportunity, :count)
      end
    end

    context 'when unit has already been marked available' do
      let!(:pool) { create(:hmis_ce_match_candidate_pool) }
      let!(:opportunity) do
        unit_group.update!(candidate_pool: pool)
        post_graphql(**variables) { mutation }
        unit.reload.latest_opportunity
      end

      it 'does not create a new opportunity' do
        expect do
          expect_gql_error(
            post_graphql(**variables) { mutation },
            message: 'Unit already has an active opportunity',
          )
          unit.reload
        end.to not_change(Hmis::Ce::Opportunity, :count)
        expect(unit.latest_opportunity).to eq(opportunity)
      end
    end

    context 'when unit has an in-progress referral' do
      let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: :locked) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: :in_progress) }

      it 'does not create a new opportunity' do
        expect do
          expect_gql_error(
            post_graphql(**variables) { mutation },
            message: 'Unit already has an active opportunity',
          )
          unit.reload
        end.to not_change(Hmis::Ce::Opportunity, :count)
        expect(unit.latest_opportunity).to eq(opportunity)
      end
    end

    context 'when unit was marked available in the past, and opportunity was filled' do
      let!(:pool) { create(:hmis_ce_match_candidate_pool) }
      let!(:past_opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, created_at: 2.years.ago, status: :closed) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: past_opportunity, data_source: ds1, created_at: 2.years.ago, status: :accepted) }

      before do
        unit_group.update!(candidate_pool: pool)
      end

      it 'creates a new opportunity' do
        expect(unit.opportunities).to include(past_opportunity)
        expect(unit.latest_opportunity.status).to eq('closed')
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          unit.reload
        end.to change(Hmis::Ce::Opportunity, :count).by(1)
        expect(unit.latest_opportunity).not_to eq(past_opportunity)
        expect(unit.latest_opportunity.status).to eq('open')
      end
    end

    context 'with many units' do
      let!(:pool) { create(:hmis_ce_match_candidate_pool) }
      let!(:unit_ids) do
        unit_group.update!(candidate_pool: pool)
        50.times.map do
          create(:hmis_unit, project: project, unit_type: unit_type, unit_group: unit_group).id
        end
      end

      let(:variables) do
        { unitIds: unit_ids }
      end

      it 'makes a reasonable number of db queries' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
        end.to make_database_queries(count: 20..35)
        expect(Hmis::Ce::Opportunity.where(unit_id: unit_ids).count).to eq(unit_ids.count)
      end
    end

    context 'when user lacks permission' do
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: :can_view_units) }

      it 'raises access denied' do
        expect do
          expect_gql_error(
            post_graphql(**variables) { mutation },
            message: 'access denied',
          )
          unit.reload
        end.to not_change(Hmis::Ce::Opportunity, :count)
      end
    end
  end
end
