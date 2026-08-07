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

    doc = Nokogiri::HTML(response.body)
    notes_row = doc.css('tr').find { |tr| tr.css('td').any? { |td| td.text.strip == 'Notes' } }
    expect(notes_row).to be_present
    expect(notes_row.at_css('td.text-right').text.strip).to eq('1')
  end
end

RSpec.describe ClientsController, '#unmerge', type: :request do
  let(:destination_ds) { create(:destination_data_source) }
  let(:source_ds) { create(:visible_data_source) }
  let(:user) { create(:user) }

  let(:destination_client) { create(:hud_client, data_source_id: destination_ds.id) }
  let(:source_a) { create(:hud_client, data_source_id: source_ds.id) }
  let(:source_b) { create(:hud_client, data_source_id: source_ds.id) }
  let!(:note) { create(:grda_warehouse_client_notes_window_note, client_id: destination_client.id) }
  let!(:client_file) { create(:client_file, client: destination_client) }

  before do
    user.legacy_roles << create(:can_edit_clients)
    user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_a.id, id_in_source: source_a.PersonalID)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_b.id, id_in_source: source_b.PersonalID)
    sign_in user
  end

  it 'splits off the selected source client, moving only the checked categories to the chosen receiver, via real form params' do
    patch(
      unmerge_client_path(destination_client),
      params: {
        grda_warehouse_hud_client: {
          unmerge: [source_a.id.to_s],
          receiver: source_a.id.to_s,
          item_categories: ['notes'],
        },
      },
    )

    expect(response).to redirect_to(edit_client_path(destination_client))
    new_destination = source_a.reload.destination_client
    expect(new_destination).to be_present
    expect(new_destination).not_to eq(destination_client)
    expect(note.reload.client_id).to eq(new_destination.id)
    expect(client_file.reload.client_id).to eq(destination_client.id)
  end
end

RSpec.describe ClientsController, '#edit suggested matches', type: :request do
  let(:destination_ds) { create(:destination_data_source) }
  let(:active_ds) { create(:visible_data_source, short_name: 'ACTIVE') }
  let(:deleted_ds) { create(:visible_data_source, short_name: 'DELETED') }
  let(:user) { create(:user) }

  let(:destination_client) { create(:hud_client, data_source_id: destination_ds.id) }
  let(:own_source) { create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: active_ds.id) }

  before do
    user.legacy_roles << create(:can_edit_clients)
    user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: own_source.id, id_in_source: own_source.PersonalID)
    sign_in user
  end

  it 'omits a suggested match entirely once every one of its source clients has a deleted data source' do
    fully_deleted_match_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: deleted_ds.id)
    fully_deleted_match_destination = create(:hud_client, data_source_id: destination_ds.id)
    GrdaWarehouse::WarehouseClient.create!(destination_id: fully_deleted_match_destination.id, source_id: fully_deleted_match_source.id, id_in_source: fully_deleted_match_source.PersonalID)
    deleted_ds.destroy

    get edit_client_path(destination_client)

    expect(response.body).not_to include(fully_deleted_match_destination.pii_provider(user: user).full_name)
  end

  it "filters a suggested match's deleted-data-source source client out of the displayed source list" do
    match_source_active = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: active_ds.id)
    match_source_deleted = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: deleted_ds.id)
    match_destination = create(:hud_client, data_source_id: destination_ds.id)
    GrdaWarehouse::WarehouseClient.create!(destination_id: match_destination.id, source_id: match_source_active.id, id_in_source: match_source_active.PersonalID)
    GrdaWarehouse::WarehouseClient.create!(destination_id: match_destination.id, source_id: match_source_deleted.id, id_in_source: match_source_deleted.PersonalID)
    deleted_ds.destroy

    get edit_client_path(destination_client)

    expect(response.body).to include("in #{active_ds.short_name}")
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css("input##{match_source_deleted.id}")).to be_nil
  end
end
