###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DestinationClientRestriction, type: :model do
  let(:user) { create(:user) }
  let(:source_ds) { create(:source_data_source) }
  let!(:dest_ds) { create(:destination_data_source) }
  let(:source) { create(:hud_client, data_source: source_ds) }
  let(:destination) { create(:hud_client, data_source: dest_ds) }
  let(:other_source) { create(:hud_client, data_source: source_ds) }
  let(:other_destination) { create(:hud_client, data_source: dest_ds) }

  before do
    create(:warehouse_client, source_id: source.id, destination_id: destination.id)
    create(:warehouse_client, source_id: other_source.id, destination_id: other_destination.id)
  end

  subject(:restriction) { described_class.new(destination) }

  def restrict_in_hmis(client)
    Hmis::RestrictedRecord.create!(
      restrictable_id: client.id,
      restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE,
      data_source_id: client.data_source_id,
      created_by: Hmis::User.find(user.id),
    )
  end

  def active_rows_for(client)
    Hmis::RestrictedRecord.for_clients.where(restrictable_id: client.id)
  end

  it 'rejects a source client' do
    expect { described_class.new(source) }.to raise_error(ArgumentError)
  end

  describe '#restrict!' do
    it 'writes one active row on the destination, created by the acting user' do
      restriction.restrict!(user: user)
      expect(active_rows_for(destination).pluck(:data_source_id, :created_by_id)).to eq([[dest_ds.id, user.id]])
    end

    it 'hides the destination and its source, and leaves an unrelated identity visible' do
      restriction.restrict!(user: user)
      asked = [destination.id, source.id, other_destination.id, other_source.id]
      expect(GrdaWarehouse::HiddenClients.restricted_subset(asked)).to eq(Set[destination.id, source.id])
    end

    it 'keeps a single active row when called twice' do
      2.times { restriction.restrict!(user: user) }
      expect(active_rows_for(destination).count).to eq(1)
    end
  end

  describe '#unrestrict!' do
    it 'removes the destination row' do
      restriction.restrict!(user: user)
      restriction.unrestrict!
      expect(active_rows_for(destination).count).to eq(0)
      expect(GrdaWarehouse::HiddenClients.restricted_subset([destination.id])).to eq(Set.new)
    end

    it 'returns true when it removed a row and false when there was none' do
      restriction.restrict!(user: user)
      expect([restriction.unrestrict!, restriction.unrestrict!]).to eq([true, false])
    end

    it 'leaves an HMIS restriction on a source in place' do
      restrict_in_hmis(source)
      restriction.restrict!(user: user)
      restriction.unrestrict!
      expect(active_rows_for(source).count).to eq(1)
      expect(restriction.restricted?).to be true
    end
  end

  describe 'state predicates' do
    it 'reports a warehouse-only restriction' do
      restriction.restrict!(user: user)
      expect([restriction.restricted_in_warehouse?, restriction.restricted_in_hmis?, restriction.restricted?]).to eq([true, false, true])
    end

    it 'reports an HMIS-only restriction' do
      restrict_in_hmis(source)
      expect([restriction.restricted_in_warehouse?, restriction.restricted_in_hmis?, restriction.restricted?]).to eq([false, true, true])
    end

    it 'ignores a restriction on another identity' do
      restrict_in_hmis(other_source)
      described_class.new(other_destination).restrict!(user: user)
      expect([restriction.restricted_in_warehouse?, restriction.restricted_in_hmis?, restriction.restricted?]).to eq([false, false, false])
    end
  end

  describe '#versions' do
    around do |example|
      PaperTrail.enabled = true
      example.run
    ensure
      PaperTrail.enabled = false
    end

    it 'lists restriction changes on the destination and its sources, newest first, and none from other identities' do
      restrict_in_hmis(source)
      restriction.restrict!(user: user)
      restriction.unrestrict!
      described_class.new(other_destination).restrict!(user: user)

      expect(restriction.versions.pluck(:event, :client_id)).to eq(
        [
          ['destroy', destination.id],
          ['create', destination.id],
          ['create', source.id],
        ],
      )
    end
  end
end
