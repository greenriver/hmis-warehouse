###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientMatchesController, '#index', type: :request do
  let(:destination_ds) { create(:destination_data_source) }
  let(:source_ds) { create(:visible_data_source) }
  let(:user) { create(:user) }

  let(:existing_source) { create(:hud_client, FirstName: 'Existing', LastName: 'Client', data_source_id: source_ds.id) }
  let(:existing_destination) { create(:hud_client, data_source_id: destination_ds.id) }
  let(:proposed_source) { create(:hud_client, FirstName: '<script>alert(1)</script>', LastName: 'Proposed', data_source_id: source_ds.id) }
  let(:proposed_destination) { create(:hud_client, data_source_id: destination_ds.id) }

  before do
    user.legacy_roles << create(:can_edit_clients)
    user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
    GrdaWarehouse::WarehouseClient.create!(destination_id: existing_destination.id, source_id: existing_source.id, id_in_source: existing_source.PersonalID)
    GrdaWarehouse::WarehouseClient.create!(destination_id: proposed_destination.id, source_id: proposed_source.id, id_in_source: proposed_source.PersonalID)
    GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: existing_source.id, source_client_id: proposed_source.id, score: -5.0)
    sign_in user
  end

  it 'escapes a client full name embedded in the accept-tooltip markup, rather than injecting it verbatim' do
    get client_matches_path

    expect(response.body).not_to include('<script>alert(1)</script>')
    expect(response.body).to include(CGI.escapeHTML('<script>alert(1)</script>'))
  end

  it 'renders the accept-tooltip without error when a matched client has no name on file' do
    blank_name_source = create(:hud_client, data_source_id: source_ds.id)
    blank_name_destination = create(:hud_client, data_source_id: destination_ds.id)
    GrdaWarehouse::WarehouseClient.create!(destination_id: blank_name_destination.id, source_id: blank_name_source.id, id_in_source: blank_name_source.PersonalID)
    GrdaWarehouse::ClientMatch.create!(status: 'candidate', destination_client_id: blank_name_source.id, source_client_id: proposed_source.id, score: -5.0)

    get client_matches_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("into existing: <br> #{blank_name_source.uuid}")
  end
end
