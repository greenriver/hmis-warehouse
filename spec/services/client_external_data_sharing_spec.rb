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

  describe '.cde_definition' do
    it 'returns the CDE definition by key and owner_type' do
      expect(ClientExternalDataSharing.cde_definition.id).to eq(cde_definition.id)
    end

    it 'returns nil when definition does not exist' do
      cde_definition.destroy
      expect(ClientExternalDataSharing.cde_definition).to be_nil
    end
  end

  describe '#excluded?' do
    it 'returns false when no CDE exists' do
      expect(ClientExternalDataSharing.new(client).excluded?).to be false
    end

    it 'returns true when value_boolean is true' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      expect(ClientExternalDataSharing.new(client).excluded?).to be true
    end

    it 'returns false when value_boolean is false' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: false)
      expect(ClientExternalDataSharing.new(client).excluded?).to be false
    end

    it 'returns false for a different client when only the first is excluded' do
      other_client = create(:hud_client, data_source: data_source)
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      expect(ClientExternalDataSharing.new(other_client).excluded?).to be false
    end

    it 'returns false when no CDE definition exists' do
      cde_definition.destroy
      expect(ClientExternalDataSharing.new(client).excluded?).to be false
    end
  end

  describe '#set_exclusion!' do
    it 'sets value to true' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.value_boolean).to be true
    end

    it 'sets value to false (upsert, does not delete)' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      ClientExternalDataSharing.new(client).set_exclusion!(value: false)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.value_boolean).to be false
    end

    it 'is idempotent when called twice with true' do
      svc = ClientExternalDataSharing.new(client)
      expect { 2.times { svc.set_exclusion!(value: true) } }.not_to raise_error
      expect(ClientExternalDataSharing.new(client).excluded?).to be true
    end

    it 'stores the warehouse user id in UserID when a user is provided' do
      user = create(:user)
      ClientExternalDataSharing.new(client).set_exclusion!(value: true, user: user)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.UserID).to eq(user.id.to_s)
    end

    it 'stores the system user id in UserID when no user is provided' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      cde = Hmis::Hud::CustomDataElement.find_by(owner_type: GrdaWarehouse::Hud::Client.name, owner_id: client.id)
      expect(cde.UserID).to eq(User.system_user.id.to_s)
    end

    it 'returns early without error when definition does not exist' do
      cde_definition.destroy
      expect { ClientExternalDataSharing.new(client).set_exclusion!(value: true) }.not_to raise_error
      expect(Hmis::Hud::CustomDataElement.count).to eq(0)
    end
  end

  describe '#last_update' do
    it 'returns nil when no CDE exists' do
      expect(ClientExternalDataSharing.new(client).last_update).to be_nil
    end

    it 'returns updated_at and system user name when no user is provided' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      info = ClientExternalDataSharing.new(client).last_update
      expect(info[:updated_by]).to eq(User.system_user.name)
      expect(info[:updated_at]).to be_a(Time).and(be_within(5.seconds).of(Time.current))
    end

    it 'returns the user name when a warehouse user set the flag' do
      user = create(:user)
      ClientExternalDataSharing.new(client).set_exclusion!(value: true, user: user)
      info = ClientExternalDataSharing.new(client).last_update
      expect(info[:updated_by]).to eq(user.name)
    end

    it 'returns System as updated_by when the warehouse user record for the stored UserID no longer exists' do
      user = create(:user)
      ClientExternalDataSharing.new(client).set_exclusion!(value: true, user: user)
      # Point UserID at a non-existent warehouse user ID rather than destroying the user
      # record (which triggers cross-database Paranoia cascades in tests).
      Hmis::Hud::CustomDataElement.find_by(
        owner_type: GrdaWarehouse::Hud::Client.name,
        owner_id: client.id,
      ).update_column(:UserID, '-1')
      info = ClientExternalDataSharing.new(client).last_update
      expect(info[:updated_by]).to eq('System')
    end
  end

  describe '#last_update_text' do
    it 'returns nil when no CDE exists' do
      expect(ClientExternalDataSharing.new(client).last_update_text).to be_nil
    end

    it 'formats the timestamp using table_compact' do
      user = create(:user)
      # freeze_time anchors DateUpdated independently so expected is not derived
      # from last_update itself (which would make the timestamp assertion circular).
      freeze_time do
        ClientExternalDataSharing.new(client).set_exclusion!(value: true, user: user)
        expected = "Last updated #{I18n.l(Time.current, format: :table_compact)} by #{user.name}"
        expect(ClientExternalDataSharing.new(client).last_update_text).to eq(expected)
      end
    end
  end
end
