###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Delete units mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation DeleteUnits($input: DeleteUnitsInput!) {
        deleteUnits(input: $input) {
          unitIds
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_manage_units, :can_view_units]) }
  let(:unit) { create(:hmis_unit, project: p1) }

  before(:each) do
    hmis_login(user)
  end

  let(:input) do
    { input: { unitIds: [unit.id.to_s] } }
  end

  it 'deletes units' do
    versions = unit.versions.where(project_id: p1.id)
    units = Hmis::Unit.where(id: unit.id)
    expect do
      response, = post_graphql(input) { mutation }
      expect(response.status).to eq 200
    end.to change(versions, :count).by(1).
      and change(units, :count).by(-1)
  end

  context 'when unit has past opportunities and referrals' do
    let!(:past_opportunity) { create(:hmis_ce_opportunity, unit: unit, project: p1, data_source: ds1, status: :closed) }
    let!(:accepted_referral) { create(:hmis_ce_referral, opportunity: past_opportunity, data_source: ds1, status: :accepted) }
    let!(:rejected_referral) { create(:hmis_ce_referral, opportunity: past_opportunity, data_source: ds1, status: :rejected) }

    it 'deletes the unit, but not historical opportunities and referrals' do
      expect do
        response, = post_graphql(input) { mutation }
        expect(response.status).to eq 200
      end.to change(Hmis::Unit, :count).by(-1).
        and not_change(Hmis::Ce::Opportunity, :count).
        and not_change(Hmis::Ce::Referral, :count)

      expect(past_opportunity.reload.unit.deleted_at).not_to be_nil
    end

    context 'when the unit has a current active opportunity' do
      let!(:active_opportunity) { create(:hmis_ce_opportunity, unit: unit, project: p1, data_source: ds1, status: :open) }

      it 'deletes the active opportunity' do
        expect do
          response, = post_graphql(input) { mutation }
          expect(response.status).to eq 200
        end.to change(Hmis::Unit, :count).by(-1).
          and change(Hmis::Ce::Opportunity, :count).by(-1).
          and not_change(Hmis::Ce::Referral, :count)

        expect(active_opportunity.reload.deleted_at).not_to be_nil
      end
    end
  end
end
