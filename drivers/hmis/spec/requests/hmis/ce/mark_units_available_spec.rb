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
  let!(:template) { create :hmis_workflow_definition_template, status: 'published' }
  let!(:unit_type) { create :hmis_unit_type, description: '1 Bedroom Apartment' }
  let!(:unit) { create :hmis_unit, project: project, unit_type: unit_type }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  describe 'mark unit available mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation MarkUnitsAvailable($unitIds: [ID!]!, $templateId: ID!) {
          markUnitsAvailable(unitIds: $unitIds, templateId: $templateId) {
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
      { unitIds: [unit.id], templateId: template.id }
    end

    context 'with valid input' do
      it 'creates a new opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsAvailable', 'units', 0, 'activeOpportunity', 'name')).to eq("Unit #{unit.id} - #{unit_type.description}")
          unit.reload
        end.to change(Hmis::Ce::Opportunity, :count).by(1)
        expect(unit.active_opportunity).to be_present
      end
    end

    context 'when unit is already occupied' do
      let!(:occupancy) { create :hmis_unit_occupancy, unit: unit }

      it 'does not create an opportunity' do
        expect do
          expect_gql_error(
            post_graphql(**variables) { mutation },
            message: 'Currently occupied unit cannot be marked available',
          )
          unit.reload
        end.to not_change(Hmis::Ce::Opportunity, :count)
        expect(unit.opportunities).to be_empty
      end
    end

    context 'when unit has already been marked available' do
      let!(:opportunity) do
        post_graphql(**variables) { mutation }
        unit.reload.active_opportunity
      end

      it 'does not create a new opportunity' do
        expect do
          expect_gql_error(
            post_graphql(**variables) { mutation },
            message: 'Unit already has an opportunity',
          )
          unit.reload
        end.to not_change(Hmis::Ce::Opportunity, :count)
        expect(unit.active_opportunity).to eq(opportunity)
      end
    end

    context 'when unit was marked available in the past, and opportunity was filled' do
      let!(:past_opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, created_at: 2.years.ago, status: :closed) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: past_opportunity, created_at: 2.years.ago, status: :accepted) }

      it 'creates a new opportunity' do
        expect(unit.opportunities).to include(past_opportunity)
        expect(unit.active_opportunity).to be_nil
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          unit.reload
        end.to change(Hmis::Ce::Opportunity, :count).by(1)
        expect(unit.active_opportunity).to be_present
        expect(unit.active_opportunity).not_to eq(past_opportunity)
      end
    end

    context 'with many units' do
      let!(:unit_ids) do
        50.times.map do
          create(:hmis_unit, project: project, unit_type: unit_type).id
        end
      end

      let(:variables) do
        { unitIds: unit_ids, templateId: template.id }
      end

      it 'makes a reasonable number of db queries' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
        end.to make_database_queries(count: 20..25)
        expect(Hmis::Ce::Opportunity.where(owner_id: unit_ids).count).to eq(unit_ids.count)
      end
    end
  end
end
