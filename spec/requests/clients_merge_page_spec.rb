###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientsController, '#edit merge page', type: :request do
  let(:destination_ds) { create(:destination_data_source) }
  let(:active_ds) { create(:visible_data_source) }
  let(:deleted_ds) { create(:visible_data_source) }
  let(:user) { create(:user) }

  let(:destination_client) { create(:hud_client, data_source_id: destination_ds.id) }
  let(:active_source) { create(:hud_client, FirstName: 'Amy', LastName: 'Adams', data_source_id: active_ds.id) }
  let(:deleted_source) { create(:hud_client, FirstName: 'Deleted', LastName: 'Client', data_source_id: deleted_ds.id) }

  before do
    user.legacy_roles << create(:can_edit_clients)
    user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: active_source.id, id_in_source: active_source.PersonalID)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: deleted_source.id, id_in_source: deleted_source.PersonalID)
    deleted_ds.destroy
    sign_in user
  end

  it 'does not render the split form when only one non-deleted-data-source client remains' do
    get edit_client_path(destination_client)

    expect(response.body).not_to include('splitButton')
    expect(response.body).not_to include('Deleted Client')
  end

  it 'renders the split form with the active client and per-category counts, once a second active source client is joined' do
    second_active_source = create(:hud_client, FirstName: 'Ben', LastName: 'Baker', data_source_id: active_ds.id)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: second_active_source.id, id_in_source: second_active_source.PersonalID)
    create(:grda_warehouse_client_notes_window_note, client_id: destination_client.id)

    get edit_client_path(destination_client)

    expect(response.body).to include('splitButton')
    expect(response.body).to include('Amy Adams')
    expect(response.body).to include('Ben Baker')
    expect(response.body).not_to include('Deleted Client')
    expect(response.body).to include('Custom Data Elements')
  end
end
