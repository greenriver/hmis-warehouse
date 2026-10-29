###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, '#merge_from and #split restriction', type: :model do
  let(:source_ds) { create(:source_data_source) }
  let!(:dest_ds) { create(:destination_data_source) }
  let(:reviewer) { create(:user) }
  let(:source_a) { create(:hud_client, data_source: source_ds) }
  let(:source_b) { create(:hud_client, data_source: source_ds) }
  let!(:dest_a) { make_destination(source_a) }
  let!(:dest_b) { make_destination(source_b) }

  def make_destination(source_client)
    dest = GrdaWarehouse::Hud::Client.create!(source_client.attributes.except('id').merge('data_source_id' => dest_ds.id))
    GrdaWarehouse::WarehouseClient.create!(
      id_in_source: source_client.PersonalID,
      data_source_id: source_client.data_source_id,
      source_id: source_client.id,
      destination_id: dest.id,
    )
    dest
  end

  describe '#merge_from' do
    it 'restricts the surviving destination when the merged-away one was restricted, keeping the moved source hidden' do
      DestinationClientRestriction.new(dest_a).restrict!(user: reviewer)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false)
      expect(DestinationClientRestriction.new(dest_b).restricted_in_warehouse?).to be true
      expect(GrdaWarehouse::HiddenClients.restricted_subset([dest_b.id, source_a.id, source_b.id])).to eq(Set[dest_b.id, source_a.id, source_b.id])
    end

    it 'restricts the survivor when a single source is merged in from a restricted destination that keeps other sources' do
      source_c = create(:hud_client, data_source: source_ds)
      GrdaWarehouse::WarehouseClient.create!(
        id_in_source: source_c.PersonalID, data_source_id: source_c.data_source_id,
        source_id: source_c.id, destination_id: dest_a.id
      )
      DestinationClientRestriction.new(dest_a).restrict!(user: reviewer)
      dest_b.merge_from(source_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false)
      expect(GrdaWarehouse::HiddenClients.restricted_subset([dest_b.id, source_a.id, source_b.id, dest_a.id, source_c.id])).
        to eq(Set[dest_b.id, source_a.id, source_b.id, dest_a.id, source_c.id])
    end

    it 'merges from a destination with sources that is not in a destination data source' do
      dest_a.update_columns(data_source_id: source_ds.id)
      expect { dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false) }.not_to raise_error
      expect(GrdaWarehouse::WarehouseClient.find_by!(source_id: source_a.id).destination_id).to eq(dest_b.id)
    end

    it 'rolls back the merge when the merged-away destination is restricted and the survivor is outside a destination data source' do
      DestinationClientRestriction.new(dest_a).restrict!(user: reviewer)
      dest_b.update_columns(data_source_id: source_ds.id)

      expect { dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false) }.
        to raise_error(ArgumentError, 'Must be a destination client')
      expect(GrdaWarehouse::WarehouseClient.find_by!(source_id: source_a.id).destination_id).to eq(dest_a.id)
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: [dest_a.id, dest_b.id]).pluck(:restrictable_id)).to eq([dest_a.id])
    end

    it 'leaves the surviving destination unrestricted when neither was restricted' do
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false)
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: dest_b.id).count).to eq(0)
    end

    it 'removes the row from the merged-away destination once it is destroyed' do
      DestinationClientRestriction.new(dest_a).restrict!(user: reviewer)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false)
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: dest_a.id).count).to eq(0)
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: dest_b.id).count).to eq(1)
    end

    it 'attributes the carried restriction to the reviewer' do
      DestinationClientRestriction.new(dest_a).restrict!(user: create(:user))
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false)
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: dest_b.id).pluck(:created_by_id)).to eq([reviewer.id])
    end

    it 'keeps the row on a restricted destination that still has sources after one is merged out' do
      source_c = create(:hud_client, data_source: source_ds)
      GrdaWarehouse::WarehouseClient.create!(
        id_in_source: source_c.PersonalID, data_source_id: source_c.data_source_id,
        source_id: source_c.id, destination_id: dest_a.id
      )
      DestinationClientRestriction.new(dest_a).restrict!(user: reviewer)
      dest_b.merge_from(source_a, reviewed_by: reviewer, reviewed_at: Time.current, cleanup: false)
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: dest_a.id).count).to eq(1)
    end
  end

  describe '#split' do
    let(:source_c) { create(:hud_client, data_source: source_ds) }

    before do
      GrdaWarehouse::WarehouseClient.create!(
        id_in_source: source_c.PersonalID, data_source_id: source_c.data_source_id,
        source_id: source_c.id, destination_id: dest_a.id
      )
    end

    def new_destination_for(source)
      GrdaWarehouse::Hud::Client.find(GrdaWarehouse::WarehouseClient.find_by!(source_id: source.id).destination_id)
    end

    it 'keeps a warehouse restriction on both sides of the split, attributing the new one to the splitting user' do
      DestinationClientRestriction.new(dest_a).restrict!(user: create(:user))
      dest_a.split([source_c.id], nil, [], reviewer)
      new_dest = new_destination_for(source_c)
      expect(new_dest.id).not_to eq(dest_a.id)
      expect([DestinationClientRestriction.new(dest_a.reload).restricted_in_warehouse?, DestinationClientRestriction.new(new_dest).restricted_in_warehouse?]).to eq([true, true])
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: new_dest.id).pluck(:created_by_id)).to eq([reviewer.id])
    end

    it 'opens the side without the source restricted in HMIS' do
      Hmis::RestrictedRecord.create!(
        restrictable_id: source_a.id,
        restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE,
        data_source_id: source_a.data_source_id,
        created_by: Hmis::User.find(reviewer.id),
      )
      dest_a.split([source_c.id], nil, [], reviewer)
      new_dest = new_destination_for(source_c)
      expect(GrdaWarehouse::HiddenClients.restricted_subset([dest_a.id, source_a.id, new_dest.id, source_c.id])).
        to eq(Set[dest_a.id, source_a.id])
    end

    it 'leaves a split-off destination unrestricted when the original was not restricted' do
      dest_a.split([source_c.id], nil, [], reviewer)
      new_dest = new_destination_for(source_c)
      expect(new_dest.id).not_to eq(dest_a.id)
      expect(Hmis::RestrictedRecord.for_clients.where(restrictable_id: new_dest.id).count).to eq(0)
    end
  end
end
