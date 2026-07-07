###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, '#merge_from and #split external data sharing', type: :model do
  let(:source_ds) { create(:source_data_source) }
  let(:dest_ds)   { create(:destination_data_source) }
  let(:source_a) { create(:hud_client, data_source: source_ds) }
  let(:source_b) { create(:hud_client, data_source: source_ds) }
  let!(:dest_a)  { make_destination(source_a) }
  let!(:dest_b)  { make_destination(source_b) }

  def make_destination(source_client)
    dest = GrdaWarehouse::Hud::Client.create!(
      source_client.attributes.except('id').merge('data_source_id' => dest_ds.id),
    )
    GrdaWarehouse::WarehouseClient.create!(
      id_in_source: source_client.PersonalID,
      data_source_id: source_client.data_source_id,
      source_id: source_client.id,
      destination_id: dest.id,
    )
    dest
  end

  # merge_from contexts

  context 'when the merged-away client was excluded' do
    before { ClientExternalDataSharing.new(dest_a).set_exclusion!(value: true) }

    it 'marks the surviving client as excluded after merging dest_a into dest_b' do
      reviewer = create(:user)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current)
      expect(ClientExternalDataSharing.new(dest_b).excluded?).to be true
    end
  end

  context 'when neither client was excluded' do
    it 'does not mark the surviving client as excluded' do
      reviewer = create(:user)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current)
      expect(ClientExternalDataSharing.new(dest_b).excluded?).to be false
      # Verify no ClientAttribute row at all was written for dest_b.
      expect(GrdaWarehouse::ClientAttribute.where(client_id: dest_b.id).count).to eq(0)
    end
  end

  context 'when the surviving client was already excluded and the merged-away client was not' do
    before { ClientExternalDataSharing.new(dest_b).set_exclusion!(value: true) }

    it 'preserves the surviving client exclusion after merge' do
      reviewer = create(:user)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current)
      expect(ClientExternalDataSharing.new(dest_b).excluded?).to be true
    end
  end

  context 'when both clients were excluded' do
    before do
      ClientExternalDataSharing.new(dest_a).set_exclusion!(value: true)
      ClientExternalDataSharing.new(dest_b).set_exclusion!(value: true)
    end

    it 'surviving client remains excluded without error (idempotent set_exclusion!)' do
      reviewer = create(:user)
      expect { dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current) }.not_to raise_error
      expect(ClientExternalDataSharing.new(dest_b).excluded?).to be true
    end
  end

  context 'when the merged-away client had exclusion explicitly unchecked' do
    before do
      ClientExternalDataSharing.new(dest_a).set_exclusion!(value: true)
      ClientExternalDataSharing.new(dest_a).set_exclusion!(value: false)
    end

    it 'does not mark the surviving client as excluded' do
      reviewer = create(:user)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current)
      expect(ClientExternalDataSharing.new(dest_b).excluded?).to be false
    end
  end

  # split contexts
  #
  # The split method dups the source client and saves it into the destination data source.
  # If the destination was created by copying the source's PersonalID (as make_destination does),
  # the dup would conflict on (PersonalID, data_source_id). These contexts use a fresh source
  # client and a destination created with an independent factory PersonalID to avoid that conflict.

  describe '#split external data sharing carry-forward' do
    # ClientCleanupJob runs after split and removes destinations whose source clients have no
    # enrollments (which is the case here). We only want to test the carry-forward logic that
    # runs synchronously inside split, so we check the new destination before the cleanup job
    # fires by not using perform_enqueued_jobs.

    let(:split_source) { create(:hud_client, data_source: source_ds) }
    # dest created with its own factory-generated PersonalID so split can dup split_source
    # into dest_ds without conflicting on the (PersonalID, data_source_id) unique index.
    let!(:split_dest) do
      dest = create(:hud_client, data_source: dest_ds)
      GrdaWarehouse::WarehouseClient.create!(
        id_in_source: split_source.PersonalID,
        data_source_id: split_source.data_source_id,
        source_id: split_source.id,
        destination_id: dest.id,
      )
      dest
    end

    def new_dest_after_split(reviewer)
      split_dest.split([split_source.id], nil, nil, reviewer)
      new_wc = GrdaWarehouse::WarehouseClient.where(source_id: split_source.id).first
      GrdaWarehouse::Hud::Client.find_by(id: new_wc&.destination_id)
    end

    context 'when the original destination was excluded' do
      before { ClientExternalDataSharing.new(split_dest).set_exclusion!(value: true) }

      it 'marks the split-off destination as excluded' do
        reviewer = create(:user)
        new_dest = new_dest_after_split(reviewer)
        expect(new_dest).to be_present
        expect(ClientExternalDataSharing.new(new_dest).excluded?).to be true
      end
    end

    context 'when the original destination was not excluded' do
      it 'does not mark the split-off destination as excluded' do
        reviewer = create(:user)
        new_dest = new_dest_after_split(reviewer)
        expect(new_dest).to be_present
        expect(ClientExternalDataSharing.new(new_dest).excluded?).to be false
      end
    end

    context 'when the original destination had exclusion explicitly unchecked' do
      before do
        ClientExternalDataSharing.new(split_dest).set_exclusion!(value: true)
        ClientExternalDataSharing.new(split_dest).set_exclusion!(value: false)
      end

      it 'does not mark the split-off destination as excluded' do
        reviewer = create(:user)
        new_dest = new_dest_after_split(reviewer)
        expect(new_dest).to be_present
        expect(ClientExternalDataSharing.new(new_dest).excluded?).to be false
      end
    end
  end

  describe 'associations' do
    it 'exposes client_attribute via has_one' do
      expect(dest_a.client_attribute).to be_nil # none created yet
      ClientExternalDataSharing.new(dest_a).set_exclusion!(value: true)
      dest_a.reload
      expect(dest_a.client_attribute).to be_a(GrdaWarehouse::ClientAttribute)
      expect(dest_a.client_attribute.client_id).to eq(dest_a.id)
    end

    it 'destroys the client_attribute when the destination client is destroyed' do
      ClientExternalDataSharing.new(dest_a).set_exclusion!(value: true)
      attr_id = dest_a.client_attribute.reload.id
      dest_a.destroy
      expect(GrdaWarehouse::ClientAttribute.where(id: attr_id)).to be_empty
    end

    it 'exposes the client via belongs_to :client on ClientAttribute' do
      ClientExternalDataSharing.new(dest_a).set_exclusion!(value: true)
      attr = GrdaWarehouse::ClientAttribute.find_by(client_id: dest_a.id)
      expect(attr.client).to eq(dest_a)
    end
  end
end
