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

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_units, :can_update_unit_availability]) }
  let!(:project) { create :hmis_hud_project, data_source: ds1 }
  let!(:unit_group) { create(:hmis_unit_group, project: project) }
  let!(:unit) { create :hmis_unit, project: project, unit_group: unit_group }
  let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: 'open') }

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
              latestOpportunity {
                id
                name
                status
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
      end.to not_change(opportunity, :status).from('open').
        and not_change(unit, :latest_opportunity)
    end

    context 'with valid input' do
      it 'closes the opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsUnavailable', 'units', 0, 'latestOpportunity', 'status')).to eq('closed')
          opportunity.reload
        end.to change(opportunity, :status).from('open').to('closed')
      end
    end

    context 'when user lacks permission' do
      let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: :can_view_units) }

      it 'does not allow' do
        expect_failure('access denied')
      end
    end

    context 'when unit is already not available' do
      let!(:opportunity) { create(:hmis_ce_opportunity) } # overwrite opportunity fixture with an opportunity that's not associated with this unit

      it 'does not allow marking unavailable' do
        expect_failure('Not found')
      end
    end

    context 'when opportunity has active referral' do
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1) }

      it 'does not allow marking unavailable' do
        expect_failure('Cannot mark opportunity unavailable if it has an active referral')
      end
    end

    context 'when unit had an opportunity in the past that is now closed' do
      let!(:past_opportunity) { create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, created_at: 2.years.ago, status: 'closed') }
      let!(:referral) { create(:hmis_ce_referral, opportunity: past_opportunity, data_source: ds1, created_at: 2.years.ago, status: :accepted) }

      it 'closes the active opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsUnavailable', 'units', 0, 'latestOpportunity', 'id')).to eq(opportunity.id.to_s)
          opportunity.reload
        end.to change(opportunity, :status).from('open').to('closed')
      end
    end

    context 'when opportunity is active with a past rejected referral referral' do
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, created_at: 2.years.ago, status: :rejected) }

      it 'closes the opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'markUnitsUnavailable', 'units', 0, 'latestOpportunity', 'status')).to eq('closed')
          expect(result.dig('data', 'markUnitsUnavailable', 'units', 0, 'canBeMarkedAvailable')).to eq(true)
          opportunity.reload
        end.to change(opportunity, :status).from('open').to('closed')
      end
    end

    context 'when multiple units are being marked unavailable, and one of them fails' do
      let!(:units) do
        10.times.map do
          unit = create(:hmis_unit, project: project, unit_group: unit_group)
          create(:hmis_ce_opportunity, unit: unit, project: project, data_source: ds1, status: 'open')
          unit
        end
      end

      let(:variables) do
        { unitIds: units.map(&:id) }
      end

      before(:each) do
        allow_any_instance_of(Hmis::Ce::Opportunity).to receive(:close!) do |opportunity|
          # Simulate failure for just one specific opportunity (to prove that it rolls back all of the changes).
          # Set this inside a block instead of using `allow(specific_instance)` because the instances are all reloaded within the mutation
          raise RuntimeError if opportunity.id.to_s == units.last.latest_opportunity.id.to_s

          allow(opportunity).to receive(:close!).and_call_original
          opportunity.close!
        end
      end

      it 'fails the whole batch' do
        expect do
          expect_gql_error(post_graphql(**variables) { mutation })
          unit.reload
        end.to not_change(Hmis::Ce::Opportunity, :count).from(11)
      end
    end
  end
end
