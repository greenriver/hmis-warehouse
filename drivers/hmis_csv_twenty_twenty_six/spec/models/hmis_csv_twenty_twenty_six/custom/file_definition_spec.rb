###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Custom::FileDefinition do
  def config_for(extra = {})
    {
      'filename' => 'CustomThing.csv',
      'class_name' => 'CustomThing',
      'warehouse_class_name' => 'GrdaWarehouse::Hud::CustomDataElement',
      'columns' => [{ 'name' => 'CustomThingID', 'type' => 'string' }],
    }.merge(extra)
  end

  describe '#hmis_owned?' do
    it 'is true when the config declares hmis_owned: true' do
      definition = described_class.new(config_for('hmis_owned' => true))

      expect(definition.hmis_owned?).to eq(true)
    end

    it 'is false when the config omits hmis_owned' do
      definition = described_class.new(config_for)

      expect(definition.hmis_owned?).to eq(false)
    end

    it 'is false when the config declares hmis_owned: false' do
      definition = described_class.new(config_for('hmis_owned' => false))

      expect(definition.hmis_owned?).to eq(false)
    end
  end
end
