###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HudKeyRemapper.remap_value SQL parity', type: :model do
  # We plan to ingest data through a parallel DBT-based pipeline, and need to ensure
  # records processed through DBT will align with records transformed by `HudKeyRemapper`.
  # This test documents the alignment approach.
  it 'produces the same value in Postgres as the Ruby reference implementation' do
    ruby_value = HmisCsvImporter::Loader::HudKeyRemapper.remap_value('PersonalID', 'TEST-SRC', 'C-1')

    sql_value = GrdaWarehouseBase.connection.select_value(
      "SELECT md5('PersonalID' || '--' || 'TEST-SRC' || '--' || 'C-1')",
    )

    expect(sql_value).to eq(ruby_value)
  end
end
