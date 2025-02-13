require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  let!(:record) { create(:role) }
  let!(:grda_warehouse_record) { create(:grda_warehouse_hud_client) }

  describe '.find_safely' do
    context 'when given a valid integer ID' do
      it 'returns the record' do
        expect(Role.find_safely(record.id)).to eq(record) # integer lookup
        expect(Role.find_safely(record.id.to_s)).to eq(record) # string lookup
        expect(GrdaWarehouse::Hud::Client.find_safely(grda_warehouse_record.id)).to eq(grda_warehouse_record) # integer lookup
        expect(GrdaWarehouse::Hud::Client.find_safely(grda_warehouse_record.id.to_s)).to eq(grda_warehouse_record) # string lookup
      end
    end

    context 'when given an invalid non-integer ID' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { Role.find_safely('invalid_id') }.to raise_error(ActiveRecord::RecordNotFound)
        expect { Role.find_safely(nil) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { GrdaWarehouse::Hud::Client.find_safely('invalid_id') }.to raise_error(ActiveRecord::RecordNotFound)
        expect { GrdaWarehouse::Hud::Client.find_safely(nil) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when given an ID that does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { Role.find_safely(-999999) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { GrdaWarehouse::Hud::Client.find_safely(-999999) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
