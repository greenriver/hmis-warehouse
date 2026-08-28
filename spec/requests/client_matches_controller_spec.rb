###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ClientMatchesController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_edit_clients: true) }
  let!(:collection) { Collection.system_collection(:data_sources) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:candidate_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Candidate', LastName: 'Client') }
  let!(:candidate_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Candidate', last_name: 'Client') }
  let!(:match) do
    GrdaWarehouse::ClientMatch.create!(
      destination_client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id),
      source_client: GrdaWarehouse::Hud::Client.find(candidate_source_client.id),
      status: 'candidate',
      # `_client_match.haml` renders `match.score.round(2).abs` unconditionally.
      score: -1.0,
    )
  end

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: candidate_destination_client.id, source_id: candidate_source_client.id, data_source_id: hmis_ds.id, id_in_source: candidate_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the restricted destination client name in the match heading' do
    get client_matches_path

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end
end
