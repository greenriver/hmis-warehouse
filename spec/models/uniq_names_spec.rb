require 'rails_helper'

RSpec.describe UniqueName, type: :model do
  describe '.update!' do
    let!(:ds) { create :source_data_source }
    let!(:warehouse_data_source) { create :grda_warehouse_data_source, source_type: nil }
    let!(:client1) { create(:grda_warehouse_hud_client, FirstName: 'Joe', LastName: 'Smith', data_source: ds) }
    let!(:client2) { create(:grda_warehouse_hud_client, FirstName: 'Jane', LastName: 'Doe', data_source: ds) }
    let!(:existing_name) { UniqueName.create!(name: 'joe', double_metaphone: ['J', 'A']) }
    let!(:unused_name) { UniqueName.create!(name: 'bob', double_metaphone: ['PP', nil]) }

    before do
      UniqueName.update!
    end

    it 'creates new unique names' do
      expect(UniqueName.where(name: ['smith', 'jane', 'doe']).count).to eq(3)
    end

    it 'keeps existing names that are still in use' do
      expect(UniqueName.find_by(name: 'joe')).to eq(existing_name)
    end

    it 'removes names no longer in use' do
      expect(UniqueName.find_by(id: unused_name.id)).to be_nil
    end

    it 'generates double metaphone for new names' do
      expect(UniqueName.find_by(name: 'smith').double_metaphone).to be_present
    end

    it 'handles empty/nil names' do
      create(:grda_warehouse_hud_client, FirstName: '', LastName: nil)
      expect { UniqueName.update! }.not_to raise_error
    end
  end
end
