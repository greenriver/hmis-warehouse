###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteItemJob, type: :job do
  describe '#perform for a DataSource' do
    let(:data_source) { create(:grda_warehouse_data_source) }

    it 'destroys the data source and removes its system collection and access control' do
      access_control = data_source.editable_access_control # data sources support editable only
      collection = access_control.collection

      described_class.new.perform(item_class: 'GrdaWarehouse::DataSource', item_id: data_source.id)

      expect(GrdaWarehouse::DataSource.find_by(id: data_source.id)).to be_nil
      expect(Collection.find_by(id: collection.id)).to be_nil
      expect(AccessControl.find_by(id: access_control.id)).to be_nil
    end

    it 'removes the system collection but leaves non-system collections that also reference the data source' do
      system_collection = data_source.editable_access_control.collection
      non_system_collection = create(:collection)
      non_system_collection.set_viewables(data_sources: [data_source.id])

      described_class.new.perform(item_class: 'GrdaWarehouse::DataSource', item_id: data_source.id)

      expect(Collection.find_by(id: system_collection.id)).to be_nil
      expect(Collection.find_by(id: non_system_collection.id)).to eq(non_system_collection)
    end
  end
end
