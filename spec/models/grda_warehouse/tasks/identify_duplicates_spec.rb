require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::IdentifyDuplicates, type: :model do
  let(:source_data_source) { create :source_data_source }
  let(:destination_data_source) { create :grda_warehouse_data_source }

  let!(:client) { create :grda_warehouse_hud_client, data_source: source_data_source }
  let!(:destination) { create :grda_warehouse_hud_client, data_source: destination_data_source }

  it 'recognizes an obvious match' do
    expect(check_for_obvious_match(client.id)).to be destination.id
  end

  describe 'obvious match processing with a split' do
    let!(:split) { create :grda_warehouse_client_split_history, split_from: client.id, split_into: destination.id }

    it 'does not return an obvious match if it was split' do
      expect(check_for_obvious_match(client.id)).to be_nil
    end
  end

  # Check for obvious match is private...
  def check_for_obvious_match(client_id)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.send(:check_for_obvious_match, client_id)
  end
end
