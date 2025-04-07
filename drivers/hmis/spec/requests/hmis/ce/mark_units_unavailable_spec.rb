###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::Ce::MarkUnitsUnavailable, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:project) { create :hmis_hud_project, data_source: ds1 }
  let!(:template) { create :hmis_workflow_definition_template, status: 'published' }
  let!(:unit_type) { create :hmis_unit_type, description: '1 Bedroom Apartment' }
  let!(:unit) { create :hmis_unit, project: project, unit_type: unit_type }
  let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :open) }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  describe 'mark unit unavailable mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation MarkUnitsUnavailable($unitIds: [ID!]!) {
          markUnitsUnavailable(unitIds: $unitIds) {
            units {
              #{scalar_fields(Types::HmisSchema::Unit)}
              activeOpportunity {
                id
                name
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

    def expect_failure(message)
      expect do
        expect_gql_error(
          post_graphql(**variables) { mutation },
          message: message,
        )
        unit.reload
      end.to not_change(Hmis::Ce::Opportunity, :count).from(1).
        and not_change(unit, :active_opportunity)
    end

    context 'with valid input' do
      it 'destroys the opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsUnavailable', 'units', 0, 'activeOpportunity')).to be_nil
          unit.reload
        end.to change(Hmis::Ce::Opportunity, :count).from(1).to(0)
        expect(unit.active_opportunity).to be_nil
      end
    end

    context 'when unit is already occupied' do
      let!(:occupancy) { create :hmis_unit_occupancy, unit: unit }

      it 'does not allow marking unavailable' do
        expect_failure('Cannot mark occupied units unavailable')
      end
    end

    context 'when unit is already not available' do
      let!(:opportunity) { create(:hmis_ce_opportunity) } # overwrite opportunity fixture with an opportunity that's not associated with this unit

      it 'does not allow marking unavailable' do
        expect_failure('Not found')
      end
    end

    context 'when opportunity has active referral' do
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity) }

      it 'does not allow marking unavailable' do
        expect_failure('Cannot mark opportunity unavailable if it has an active referral')
      end
    end

    context 'when unit had an opportunity in the past that is now closed' do
      let!(:past_opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, created_at: 2.years.ago, status: :closed) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: past_opportunity, created_at: 2.years.ago, status: :accepted) }

      it 'destroys the active opportunity and not the past opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsUnavailable', 'units', 0, 'activeOpportunity')).to be_nil
          unit.reload
        end.to change(Hmis::Ce::Opportunity, :count).from(2).to(1)
        expect(unit.active_opportunity).to be_nil
        expect(unit.opportunities).to contain_exactly(past_opportunity)
      end
    end

    context 'with many units' do
      let!(:unit_ids) do
        50.times.map do
          unit = create(:hmis_unit, project: project, unit_type: unit_type)
          create(:hmis_ce_opportunity, owner: unit, project: project, status: :open)
          unit.id
        end
      end

      let(:variables) do
        { unitIds: unit_ids }
      end

      it 'makes a reasonable number of db queries' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
        end.to make_database_queries(count: 15..20)
        expect(Hmis::Ce::Opportunity.where(owner_id: unit_ids).count).to eq(0)
      end
    end
  end
end
