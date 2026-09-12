###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientsController, '#create restricted client duplicate check', type: :request do
  let(:source_ds) { create(:source_data_source) }
  let(:hmis_ds) { create(:hmis_primary_data_source) }
  let(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let(:user) { create(:user) }

  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Zzrestrict', last_name: 'Zzclient', ssn: '999887777', dob: Date.new(1980, 5, 5)) }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Zzrestrict', LastName: 'Zzclient', SSN: '999887777', DOB: Date.new(1980, 5, 5)) }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)

    user.legacy_roles << create(:role, can_create_clients: true, can_search_all_clients: true)
    create(:destination_data_source)
    sign_in user
  end

  def base_params(overrides)
    { client: { FirstName: 'Zzrestrict', LastName: 'Zzclient', DOB: '1980-05-05', SSN: '999-88-7777', data_source_id: source_ds.id }.merge(overrides) }
  end

  it 'creates the client outright when SSN and DOB match but the only shared name+field pair is SSN+DOB on a restricted client' do
    expect do
      post clients_path, params: base_params(FirstName: 'Different', LastName: 'Person')
    end.to change(GrdaWarehouse::Hud::Client, :count).by(2) # source + destination

    expect(flash[:notice]).to match(/created/)
  end

  it 'creates the client outright when name and DOB match but SSN differs on a restricted client' do
    expect do
      post clients_path, params: base_params(SSN: '111-22-3333')
    end.to change(GrdaWarehouse::Hud::Client, :count).by(2)

    expect(flash[:notice]).to match(/created/)
  end

  it 'still flags an obvious duplicate for an unrestricted client matching on name and DOB' do
    unrestricted_source_client = create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Zzopen', last_name: 'Zzclient', ssn: '444556666', dob: Date.new(1982, 7, 7))
    unrestricted_destination_client = create(:grda_warehouse_hud_client, FirstName: 'Zzopen', LastName: 'Zzclient', SSN: '444556666', DOB: Date.new(1982, 7, 7))
    GrdaWarehouse::WarehouseClient.create!(destination_id: unrestricted_destination_client.id, source_id: unrestricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: unrestricted_source_client.id.to_s)

    expect do
      post clients_path, params: base_params(FirstName: 'Zzopen', LastName: 'Zzclient', SSN: '999-99-9999', DOB: '1982-07-07')
    end.not_to change(GrdaWarehouse::Hud::Client, :count)

    expect(flash[:notice]).to be_nil
  end
end
