###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, '#merge_from external data sharing', type: :model do
  let(:source_ds) { create(:source_data_source) }
  let(:dest_ds)   { create(:destination_data_source) }
  let!(:cde_definition) do
    create(
      :hud_custom_data_element_definition,
      key: ClientExternalDataSharing::EXTERNAL_DATA_SHARING_CDE_KEY,
      owner_type: 'GrdaWarehouse::Hud::Client',
      field_type: 'boolean',
      data_source_id: dest_ds.id,
    )
  end

  before { GrdaWarehouse::Hud::Client.instance_variable_set(:@external_data_sharing_cde_definition, nil) }

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

  context 'when the merged-away client was excluded' do
    let(:source_a) { create(:hud_client, data_source: source_ds) }
    let(:source_b) { create(:hud_client, data_source: source_ds) }
    let!(:dest_a)  { make_destination(source_a) }
    let!(:dest_b)  { make_destination(source_b) }

    before { dest_a.set_external_data_sharing_exclusion!(value: true) }

    it 'marks the surviving client as excluded after merging dest_a into dest_b' do
      reviewer = create(:user)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current)
      expect(dest_b.excluded_from_external_data_sharing?).to be true
    end
  end

  context 'when neither client was excluded' do
    let(:source_a) { create(:hud_client, data_source: source_ds) }
    let(:source_b) { create(:hud_client, data_source: source_ds) }
    let!(:dest_a)  { make_destination(source_a) }
    let!(:dest_b)  { make_destination(source_b) }

    it 'does not mark the surviving client as excluded' do
      reviewer = create(:user)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current)
      expect(dest_b.excluded_from_external_data_sharing?).to be false
    end
  end

  context 'when the surviving client was already excluded and the merged-away client was not' do
    let(:source_a) { create(:hud_client, data_source: source_ds) }
    let(:source_b) { create(:hud_client, data_source: source_ds) }
    let!(:dest_a)  { make_destination(source_a) }
    let!(:dest_b)  { make_destination(source_b) }

    before { dest_b.set_external_data_sharing_exclusion!(value: true) }

    it 'preserves the surviving client exclusion after merge' do
      reviewer = create(:user)
      dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current)
      expect(dest_b.excluded_from_external_data_sharing?).to be true
    end
  end

  context 'when both clients were excluded' do
    let(:source_a) { create(:hud_client, data_source: source_ds) }
    let(:source_b) { create(:hud_client, data_source: source_ds) }
    let!(:dest_a)  { make_destination(source_a) }
    let!(:dest_b)  { make_destination(source_b) }

    before do
      dest_a.set_external_data_sharing_exclusion!(value: true)
      dest_b.set_external_data_sharing_exclusion!(value: true)
    end

    it 'surviving client remains excluded without error' do
      reviewer = create(:user)
      expect { dest_b.merge_from(dest_a, reviewed_by: reviewer, reviewed_at: Time.current) }.not_to raise_error
      expect(dest_b.excluded_from_external_data_sharing?).to be true
    end
  end
end
