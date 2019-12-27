require 'rails_helper'

model = GrdaWarehouse::AdHocDataSource
RSpec.describe model, type: :model do
  let!(:data_source) { create :ad_hoc_data_source }
  let!(:valid_batch) { create :ad_hoc_batch_valid }
  let!(:invalid_batch) { create :ad_hoc_batch_invalid }

  describe 'import' do
    before do
      GrdaWarehouse::AdHocBatch.process!
    end
    it 'sets import errors when headers don\'t match' do
      expect(invalid_batch.reload.import_errors).not_to be_nil
    end
    describe 'with valid import' do
      it 'creates 2 clients' do
        expect(valid_batch.ad_hoc_clients.count).to eq 2
      end
    end
  end
end
