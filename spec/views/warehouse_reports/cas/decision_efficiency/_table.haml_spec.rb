###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The full report (WarehouseReports::Cas::DecisionEfficiencyController#index) reads from
# a mirrored CAS database (CasAccess::Reporting::Decisions joined to Program/Agency/Client
# via a CAS user's role) with no factories in this codebase to build that graph. This spec
# instead renders the partial directly against a plain row hash -- the same shape
# `report_scope` plucks into `@data` -- to cover the PII redaction this batch adds to it.
RSpec.describe 'warehouse_reports/cas/decision_efficiency/_table', type: :view do
  let!(:user) { create(:acl_user) }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client) }

  let(:row) do
    {
      days: 3,
      first_ended_at: 10.days.ago,
      second_ended_at: 7.days.ago,
      match_route: 'Standard',
      program_name: 'Program',
      sub_program_name: 'Sub Program',
      match_id: 1,
      match_stated_at: 10.days.ago,
      client_move_in_date: nil,
      first_name: 'Restricted',
      last_name: 'Client',
      warehouse_client_id: restricted_destination_client.id,
      hsa_contacts: nil,
      hsp_contacts: nil,
    }
  end

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)

    assign(:data, [row])
    assign(:filter, double(first_step: 'Selected', second_step: 'Approved'))
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:can_view_clients?).and_return(true)
      allow(view).to receive(:link_params).and_return({})
    end
  end

  it 'redacts the restricted client name' do
    render

    expect(rendered).not_to include('Restricted')
    expect(rendered).to include('Name Redacted')
  end
end
