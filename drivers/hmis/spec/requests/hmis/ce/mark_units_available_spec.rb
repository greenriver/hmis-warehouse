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

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_units, :can_update_unit_availability]) }
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
                prioritySchemes {
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
        unit_group.update!(candidate_pool: pool)
      end

      it 'creates a new opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsAvailable', 'units', 0, 'latestOpportunity', 'name')).to include(unit.id.to_s)
        end.to change(Hmis::Ce::Opportunity, :count).by(1)

        unit.reload
        expect(unit.latest_opportunity.candidate_pool).to eq(pool)
        expect(unit.latest_opportunity.unit_group.workflow_template).to eq(template)
        expect(unit.latest_opportunity.created_by).to eq(hmis_user)
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
            message: /Unit must be in a Unit Group/,
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
      let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, status: :locked) }
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
      let!(:past_opportunity) { create(:hmis_ce_opportunity, unit: unit, created_at: 2.years.ago, status: :closed) }
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

    context 'when project has assigned legacy Referral Postings' do
      let!(:unit_type_2) { create :hmis_unit_type, description: '2 Bedroom Apartment' }
      let!(:unit_group_2) { create :hmis_unit_group, project: project, workflow_template: template }
      let!(:two_br_unit1) { create :hmis_unit, project: project, unit_type: unit_type_2, unit_group: unit_group_2 }
      let!(:two_br_unit2) { create :hmis_unit, project: project, unit_type: unit_type_2, unit_group: unit_group_2 }
      let!(:one_br_unit2) { create :hmis_unit, project: project, unit_type: unit_type, unit_group: unit_group }
      let!(:one_br_unit3) { create :hmis_unit, project: project, unit_type: unit_type, unit_group: unit_group }

      context 'with 2 assigned postings to 1 Bedroom Apartment' do
        let!(:assigned_posting_1) { create(:hmis_external_api_ac_hmis_referral_posting, project: project, unit_type: unit_type, status: :assigned_status) }
        let!(:assigned_posting_2) { create(:hmis_external_api_ac_hmis_referral_posting, project: project, unit_type: unit_type, status: :assigned_status) }

        it 'allows marking 1 unit when within the limit' do
          variables = { unitIds: [one_br_unit2.id] }
          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result.inspect
          end.to change(Hmis::Ce::Opportunity, :count).by(1)
        end

        it 'raises an error when trying to mark too many units' do
          # There are 2 assigned postings for 3 vacant units = 1 1BR unit can be marked available
          # But trying to mark 2 units

          variables = { unitIds: [one_br_unit2.id, one_br_unit3.id] }

          expect do
            expect_gql_error(
              post_graphql(**variables) { mutation },
              message: /Cannot mark 2 1 Bedroom Apartment units as available because of overlapping legacy Referral Postings. At most 1 1 Bedroom Apartment units can be marked available at this time./,
            )
          end.to not_change(Hmis::Ce::Opportunity, :count)
        end

        it 'allows marking units available for other unit types' do
          variables = { unitIds: [two_br_unit1.id, two_br_unit2.id] }
          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result.inspect
          end.to change(Hmis::Ce::Opportunity, :count).by(2)
        end

        context 'and other unit already has opportunity' do
          let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, status: :open) }
          # 3 vacant units - 1 already marked available (has open opportunity) - 2 assigned postings = 0 units can be marked available

          it 'raises an error when trying to mark too many units' do
            variables = { unitIds: [one_br_unit2.id] }
            expect do
              expect_gql_error(
                post_graphql(**variables) { mutation },
                message: /Cannot mark 1 1 Bedroom Apartment units as available because of overlapping legacy Referral Postings. At most 0 1 Bedroom Apartment units can be marked available at this time./,
              )
            end.to not_change(Hmis::Ce::Opportunity, :count)
          end
        end

        context 'and other unit is occupied' do
          let!(:occupancy) { create(:hmis_unit_occupancy, unit: unit) }
          it 'raises an error when trying to mark too many units' do
            variables = { unitIds: [one_br_unit2.id] }
            expect do
              expect_gql_error(
                post_graphql(**variables) { mutation },
                message: /Cannot mark 1 1 Bedroom Apartment units as available because of overlapping legacy Referral Postings. At most 0 1 Bedroom Apartment units can be marked available at this time./,
              )
            end.to not_change(Hmis::Ce::Opportunity, :count)
          end
        end
      end

      context 'when referral postings have other statuses' do
        let!(:posting1) { create(:hmis_external_api_ac_hmis_referral_posting, project: project, unit_type: unit_type, status: :assigned_status) }
        let!(:posting2) { create(:hmis_external_api_ac_hmis_referral_posting, project: project, unit_type: unit_type, status: :denied_pending_status) }
        let!(:posting3) { create(:hmis_external_api_ac_hmis_referral_posting, project: project, unit_type: unit_type, status: :accepted_pending_status) }
        let!(:posting4) { create(:hmis_external_api_ac_hmis_referral_posting, project: project, unit_type: unit_type, status: :accepted_status) }
        let!(:posting5) { create(:hmis_external_api_ac_hmis_referral_posting, project: project, unit_type: unit_type, status: :denied_status) }

        it 'counts only assigned and denied_pending statuses' do
          # 3 vacant units - 2 counted postings (assigned + denied_pending) = 1 units can be marked available
          variables = { unitIds: [one_br_unit2.id] }

          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result.inspect
          end.to change(Hmis::Ce::Opportunity, :count).by(1)
        end

        it 'rejects above threshold' do
          variables = { unitIds: [one_br_unit2.id, one_br_unit3.id] }

          expect do
            expect_gql_error post_graphql(**variables) { mutation }
          end.to not_change(Hmis::Ce::Opportunity, :count)
        end
      end
    end
  end
end
