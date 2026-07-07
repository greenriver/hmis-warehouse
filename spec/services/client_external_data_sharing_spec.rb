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

  describe '.enabled?' do
    it 'returns true when the config flag is enabled' do
      allow(GrdaWarehouse::Config).to receive(:get).
        with(:enable_external_data_sharing_exclusion).
        and_return(true)
      expect(ClientExternalDataSharing.enabled?).to be true
    end

    it 'returns false when the config flag is disabled' do
      allow(GrdaWarehouse::Config).to receive(:get).
        with(:enable_external_data_sharing_exclusion).
        and_return(false)
      expect(ClientExternalDataSharing.enabled?).to be false
    end
  end

  describe '#excluded?' do
    it 'returns false when no ClientAttribute row exists' do
      expect(ClientExternalDataSharing.new(client).excluded?).to be false
    end

    it 'returns true when flag is true' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      expect(ClientExternalDataSharing.new(client).excluded?).to be true
    end

    it 'returns false when flag is false' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: false)
      expect(ClientExternalDataSharing.new(client).excluded?).to be false
    end

    it 'returns false for a different client when only the first is excluded' do
      other_client = create(:hud_client, data_source: data_source)
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      expect(ClientExternalDataSharing.new(other_client).excluded?).to be false
    end
  end

  describe '#set_exclusion!' do
    it 'creates a ClientAttribute row with flag true' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      record = GrdaWarehouse::ClientAttribute.find_by(client_id: client.id)
      expect(record.external_data_sharing_exclusion_flag).to be true
    end

    it 'creates a ClientAttribute row with flag false when no prior row exists' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: false)
      record = GrdaWarehouse::ClientAttribute.find_by(client_id: client.id)
      expect(record).not_to be_nil
      expect(record.external_data_sharing_exclusion_flag).to be false
    end

    it 'updates an existing row to false (upsert, does not delete)' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      ClientExternalDataSharing.new(client).set_exclusion!(value: false)
      record = GrdaWarehouse::ClientAttribute.find_by(client_id: client.id)
      expect(record.external_data_sharing_exclusion_flag).to be false
    end

    it 'is idempotent when called twice with true' do
      svc = ClientExternalDataSharing.new(client)
      expect { 2.times { svc.set_exclusion!(value: true) } }.not_to raise_error
      expect(ClientExternalDataSharing.new(client).excluded?).to be true
    end

    it 'stores the warehouse user id when a user is provided' do
      user = create(:user)
      ClientExternalDataSharing.new(client).set_exclusion!(value: true, user: user)
      record = GrdaWarehouse::ClientAttribute.find_by(client_id: client.id)
      expect(record.external_data_sharing_updated_by).to eq(user.id)
    end

    it 'stores the system user id when no user is provided' do
      ClientExternalDataSharing.new(client).set_exclusion!(value: true)
      record = GrdaWarehouse::ClientAttribute.find_by(client_id: client.id)
      expect(record.external_data_sharing_updated_by).to eq(User.system_user.id)
    end
  end

  describe '#last_update' do
    it 'returns nil when no ClientAttribute row exists' do
      expect(ClientExternalDataSharing.new(client).last_update).to be_nil
    end

    it 'returns nil when a ClientAttribute row exists but the exclusion flag is nil' do
      GrdaWarehouse::ClientAttribute.create!(client_id: client.id)
      expect(ClientExternalDataSharing.new(client).last_update).to be_nil
    end

    it 'returns attribution hash when flag is false (nil guard must not treat false as nil)' do
      user = create(:user)
      ClientExternalDataSharing.new(client).set_exclusion!(value: false, user: user)
      info = ClientExternalDataSharing.new(client).last_update
      expect(info).not_to be_nil
      expect(info[:updated_by]).to eq(user.name)
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

    it 'returns System as updated_by when the stored user id no longer exists' do
      user = create(:user)
      ClientExternalDataSharing.new(client).set_exclusion!(value: true, user: user)
      GrdaWarehouse::ClientAttribute.find_by(client_id: client.id).update_column(:external_data_sharing_updated_by, -1)
      info = ClientExternalDataSharing.new(client).last_update
      expect(info[:updated_by]).to eq('System')
    end
  end

  describe '#last_update_text' do
    it 'formats the timestamp using table_compact' do
      user = create(:user)
      freeze_time do
        ClientExternalDataSharing.new(client).set_exclusion!(value: true, user: user)
        expected = "Last updated #{I18n.l(Time.current, format: :table_compact)} by #{user.name}"
        expect(ClientExternalDataSharing.new(client).last_update_text).to eq(expected)
      end
    end
  end
end
