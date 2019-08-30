require 'rails_helper'

model = GrdaWarehouse::Hud::Inventory
RSpec.describe model, type: :model do
  let!(:inventory) { create :hud_inventory }
  let(:range) { '2017-05-20'.to_date..'2017-10-20'.to_date }
  describe 'scopes' do
    it 'included within_range when no start or end' do
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 1
    end

    it 'included within_range when start is before range' do
      inventory.update(InventoryStartDate: '2017-05-10')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 1
    end

    it 'included within_range when start is before range and end is in range' do
      inventory.update(InventoryStartDate: '2017-05-10', InventoryEndDate: '2017-10-21')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 1
    end

    it 'included within_range when end is after range and start is blank' do
      inventory.update(InventoryEndDate: '2017-10-21')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 1
    end

    it 'included within_range when end is within range and start is blank' do
      inventory.update(InventoryEndDate: '2017-05-21')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 1
    end

    it 'included within_range when start and end are within range' do
      inventory.update(InventoryStartDate: '2017-09-10', InventoryEndDate: '2017-10-10')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 1
    end

    it 'included within_range when start is within range and end is after' do
      inventory.update(InventoryStartDate: '2017-09-10', InventoryEndDate: '2017-10-30')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 1
    end

    it 'not included within_range when end is before range and start is blank' do
      inventory.update(InventoryEndDate: '2017-04-30')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 0
    end

    it 'not included within_range when start is after range and end is blank' do
      inventory.update(InventoryStartDate: '2017-12-10')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 0
    end

    it 'not included within_range when start and end are after range' do
      inventory.update(InventoryStartDate: '2017-12-10', InventoryEndDate: '2018-10-30')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 0
    end

    it 'not included within_range when start and end are before range' do
      inventory.update(InventoryStartDate: '2015-12-10', InventoryEndDate: '2016-10-30')
      expect(GrdaWarehouse::Hud::Inventory.within_range(range).count).to eq 0
    end
  end
end
