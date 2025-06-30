# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientChangeMarker do
  let!(:destination_data_source) { create :destination_data_source }
  let!(:client1) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client2) { create :grda_warehouse_hud_client, data_source: destination_data_source }

  describe '.dirty' do
    let!(:dirty_marker) { create :grda_warehouse_client_change_marker, client: client1, current_version: 2, processed_version: 1 }
    let!(:clean_marker) { create :grda_warehouse_client_change_marker, client: client2, current_version: 1, processed_version: 1 }

    it 'returns only dirty markers' do
      expect(described_class.dirty).to contain_exactly(dirty_marker)
    end
  end

  describe '.upsert_or_bump_version' do
    it 'creates new markers for new clients' do
      expect { described_class.upsert_or_bump_version(client_ids: [client1.id]) }.
        to change { described_class.count }.by(1)

      marker = described_class.find_by(client_id: client1.id)
      expect(marker.current_version).to eq(1)
    end

    it 'bumps version for existing clients' do
      create :grda_warehouse_client_change_marker, client: client1, current_version: 2

      expect { described_class.upsert_or_bump_version(client_ids: [client1.id]) }.
        not_to(change { described_class.count })

      marker = described_class.find_by(client_id: client1.id)
      expect(marker.current_version).to eq(3)
    end
  end
end
