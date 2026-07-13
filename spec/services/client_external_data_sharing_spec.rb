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

  describe 'class-level scope methods' do
    let(:source_ds)     { create(:source_data_source) }
    let(:dest_ds)       { create(:destination_data_source) }
    let(:source_client) { create(:hud_client, data_source: source_ds) }
    let!(:dest_client)  { make_dest(source_client) }
    let(:client_scope)  { GrdaWarehouse::Hud::Client.where(id: dest_client.id) }

    def make_dest(src, warehouse_created_at: 30.days.ago)
      dest = GrdaWarehouse::Hud::Client.create!(
        src.attributes.except('id').merge('data_source_id' => dest_ds.id),
      )
      wc = GrdaWarehouse::WarehouseClient.create!(
        id_in_source: src.PersonalID,
        data_source_id: src.data_source_id,
        source_id: src.id,
        destination_id: dest.id,
      )
      wc.update_column(:created_at, warehouse_created_at)
      dest
    end

    describe '.externally_excluded_client_ids' do
      it 'includes the id of a client with flag: true' do
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        expect(ClientExternalDataSharing.externally_excluded_client_ids.pluck(:client_id)).to include(dest_client.id)
      end

      it 'excludes the id of a client with flag: false' do
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: false)
        expect(ClientExternalDataSharing.externally_excluded_client_ids.pluck(:client_id)).not_to include(dest_client.id)
      end

      it 'excludes the id of a client with no ClientAttribute row' do
        expect(ClientExternalDataSharing.externally_excluded_client_ids.pluck(:client_id)).not_to include(dest_client.id)
      end
    end

    describe '.embargoed_client_ids' do
      it 'includes a destination id whose warehouse_client was added within the embargo period' do
        src = create(:hud_client, data_source: source_ds)
        embargoed = make_dest(src, warehouse_created_at: 2.days.ago)
        expect(ClientExternalDataSharing.embargoed_client_ids.pluck(:destination_id)).to include(embargoed.id)
      end

      it 'excludes a destination id whose warehouse_client is older than the embargo period' do
        expect(ClientExternalDataSharing.embargoed_client_ids.pluck(:destination_id)).not_to include(dest_client.id)
      end

      it 'excludes a destination id at exactly the embargo boundary (boundary is exclusive)' do
        src = create(:hud_client, data_source: source_ds)
        boundary = make_dest(src, warehouse_created_at: ClientExternalDataSharing::EMBARGO_PERIOD.ago)
        expect(ClientExternalDataSharing.embargoed_client_ids.pluck(:destination_id)).not_to include(boundary.id)
      end
    end

    describe '.exclude_from_external' do
      it 'removes a flagged client from the scope' do
        ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
        expect(ClientExternalDataSharing.exclude_from_external(client_scope).pluck(:id)).not_to include(dest_client.id)
      end

      it 'retains a client with no exclusion flag' do
        expect(ClientExternalDataSharing.exclude_from_external(client_scope).pluck(:id)).to include(dest_client.id)
      end
    end

    describe '.exclude_for_embargo' do
      it 'removes an embargoed client from the scope' do
        src = create(:hud_client, data_source: source_ds)
        embargoed = make_dest(src, warehouse_created_at: 2.days.ago)
        scope = GrdaWarehouse::Hud::Client.where(id: embargoed.id)
        expect(ClientExternalDataSharing.exclude_for_embargo(scope).pluck(:id)).not_to include(embargoed.id)
      end

      it 'retains a non-embargoed client' do
        expect(ClientExternalDataSharing.exclude_for_embargo(client_scope).pluck(:id)).to include(dest_client.id)
      end
    end

    describe '.remove_excluded_clients' do
      context 'when feature is disabled' do
        before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(false) }

        it 'returns the scope unchanged even when a client is flagged' do
          ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
          expect(ClientExternalDataSharing.remove_excluded_clients(client_scope).pluck(:id)).to include(dest_client.id)
        end
      end

      context 'when feature is enabled' do
        before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true) }

        it 'removes a flagged client' do
          ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
          expect(ClientExternalDataSharing.remove_excluded_clients(client_scope).pluck(:id)).not_to include(dest_client.id)
        end

        it 'removes an embargoed client' do
          src = create(:hud_client, data_source: source_ds)
          embargoed = make_dest(src, warehouse_created_at: 2.days.ago)
          scope = GrdaWarehouse::Hud::Client.where(id: embargoed.id)
          expect(ClientExternalDataSharing.remove_excluded_clients(scope).pluck(:id)).not_to include(embargoed.id)
        end

        it 'retains an unflagged, non-embargoed client' do
          expect(ClientExternalDataSharing.remove_excluded_clients(client_scope).pluck(:id)).to include(dest_client.id)
        end
      end
    end

    describe '.remove_excluded_enrollments' do
      let(:project) { create(:hud_project, data_source: source_ds) }
      let!(:enrollment) do
        create(:hud_enrollment,
               data_source: source_ds,
               ProjectID: project.ProjectID,
               PersonalID: source_client.PersonalID)
      end
      let(:base_scope) { GrdaWarehouse::Hud::Enrollment.where(id: enrollment.id) }

      context 'when feature is disabled' do
        before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(false) }

        it 'returns the scope unchanged even when a client is flagged' do
          ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
          expect(ClientExternalDataSharing.remove_excluded_enrollments(base_scope).pluck(:id)).to include(enrollment.id)
        end
      end

      context 'when feature is enabled' do
        before { allow(GrdaWarehouse::Config).to receive(:get).with(:enable_external_data_sharing_exclusion).and_return(true) }

        it 'removes enrollments for a flagged client' do
          ClientExternalDataSharing.new(dest_client).set_exclusion!(value: true)
          expect(ClientExternalDataSharing.remove_excluded_enrollments(base_scope).pluck(:id)).not_to include(enrollment.id)
        end

        it 'retains enrollments for an unflagged, non-embargoed client' do
          expect(ClientExternalDataSharing.remove_excluded_enrollments(base_scope).pluck(:id)).to include(enrollment.id)
        end
      end
    end
  end
end
