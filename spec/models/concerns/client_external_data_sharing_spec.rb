###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientExternalDataSharing, type: :model do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:client) { create(:hud_client, data_source: data_source) }
  let!(:cde_definition) do
    create(
      :hud_custom_data_element_definition,
      key: ClientExternalDataSharing::EXTERNAL_DATA_SHARING_CDE_KEY,
      owner_type: GrdaWarehouse::Hud::Client.name,
      field_type: 'boolean',
      data_source_id: data_source.id,
    )
  end

  before { GrdaWarehouse::Hud::Client.instance_variable_set(:@external_data_sharing_cde_definition, nil) }

  describe '.external_data_sharing_cde_definition' do
    it 'returns the CDE definition by key and owner_type' do
      expect(GrdaWarehouse::Hud::Client.external_data_sharing_cde_definition.id).to eq(cde_definition.id)
    end

    it 'returns nil when definition does not exist' do
      cde_definition.destroy
      GrdaWarehouse::Hud::Client.instance_variable_set(:@external_data_sharing_cde_definition, nil)
      expect(GrdaWarehouse::Hud::Client.external_data_sharing_cde_definition).to be_nil
    end
  end

  describe '#excluded_from_external_data_sharing?' do
    it 'returns false when no CDE exists' do
      expect(client.excluded_from_external_data_sharing?).to be false
    end

    it 'returns true when value_boolean is true' do
      client.set_external_data_sharing_exclusion!(value: true)
      expect(client.excluded_from_external_data_sharing?).to be true
    end

    it 'returns false when value_boolean is false' do
      client.set_external_data_sharing_exclusion!(value: false)
      expect(client.excluded_from_external_data_sharing?).to be false
    end

    it 'returns false for a different client when only the first is excluded' do
      other_client = create(:hud_client, data_source: data_source)
      client.set_external_data_sharing_exclusion!(value: true)
      expect(other_client.excluded_from_external_data_sharing?).to be false
    end
  end

  describe '#set_external_data_sharing_exclusion!' do
    it 'sets value to true' do
      client.set_external_data_sharing_exclusion!(value: true)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.value_boolean).to be true
    end

    it 'sets value to false (upsert, does not delete)' do
      client.set_external_data_sharing_exclusion!(value: true)
      client.set_external_data_sharing_exclusion!(value: false)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.value_boolean).to be false
    end

    it 'is idempotent when called twice with true' do
      expect { 2.times { client.set_external_data_sharing_exclusion!(value: true) } }.not_to raise_error
      expect(client.excluded_from_external_data_sharing?).to be true
    end

    it 'stores user id in UserID when user is provided' do
      user = create(:user)
      client.set_external_data_sharing_exclusion!(value: true, user: user)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.UserID).to eq(user.id.to_s)
    end

    it 'stores system in UserID when no user is provided' do
      client.set_external_data_sharing_exclusion!(value: true)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.UserID).to eq('system')
    end

    it 'returns early without error when definition does not exist' do
      cde_definition.destroy
      GrdaWarehouse::Hud::Client.instance_variable_set(:@external_data_sharing_cde_definition, nil)
      expect { client.set_external_data_sharing_exclusion!(value: true) }.not_to raise_error
      expect(Hmis::Hud::CustomDataElement.count).to eq(0)
    end
  end

  describe '#external_data_sharing_last_update' do
    it 'returns nil when no CDE exists' do
      expect(client.external_data_sharing_last_update).to be_nil
    end

    it 'returns updated_at and System when UserID is system' do
      client.set_external_data_sharing_exclusion!(value: true)
      info = client.external_data_sharing_last_update
      expect(info[:updated_by]).to eq('System')
      expect(info[:updated_at]).to be_a(Time).and(be_within(5.seconds).of(Time.current))
    end

    it 'returns the user name when a warehouse user set the flag' do
      user = create(:user)
      client.set_external_data_sharing_exclusion!(value: true, user: user)
      info = client.external_data_sharing_last_update
      expect(info[:updated_by]).to eq(user.name)
    end

    it 'returns System as updated_by when the user who set the flag no longer exists' do
      user = create(:user)
      client.set_external_data_sharing_exclusion!(value: true, user: user)
      # Simulate a deleted user by pointing UserID at a non-existent ID rather than
      # destroying the user record (which triggers cross-database Paranoia cascades in tests).
      Hmis::Hud::CustomDataElement.find_by(
        owner_type: GrdaWarehouse::Hud::Client.name,
        owner_id: client.id,
      ).update_column(:UserID, '999999')
      info = client.external_data_sharing_last_update
      expect(info[:updated_by]).to eq('System')
    end
  end

  describe '#external_data_sharing_last_update_text' do
    it 'returns nil when no CDE exists' do
      expect(client.external_data_sharing_last_update_text).to be_nil
    end

    it 'formats the timestamp using table_compact' do
      user = create(:user)
      client.set_external_data_sharing_exclusion!(value: true, user: user)
      info = client.external_data_sharing_last_update
      expected = "Last updated #{I18n.l(info[:updated_at], format: :table_compact)} by #{user.name}"
      expect(client.external_data_sharing_last_update_text).to eq(expected)
    end
  end
end
