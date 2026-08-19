###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hmis_csv_remap_key SQL function', type: :model do
  it 'produces the same value as the Ruby reference implementation' do
    ruby_value = HmisCsvImporter::Loader::HudKeyRemapper.remap_value('PersonalID', 'TEST-SRC', 'C-1')

    # The function lives in the warehouse database (see GrdaWarehouseBase's `connects_to`),
    # not the primary database ActiveRecord::Base itself connects to.
    sql_value = GrdaWarehouseBase.connection.select_value(
      "SELECT hmis_csv_remap_key('PersonalID', 'TEST-SRC', 'C-1')",
    )

    expect(sql_value).to eq(ruby_value)
  end
end
