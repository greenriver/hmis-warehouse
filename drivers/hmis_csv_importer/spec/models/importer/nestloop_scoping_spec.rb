###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::Importer, type: :model do
  # Test design: Tier 2 — issue 9211: with_sql_log used to disable nested-loop
  # joins for entire import phases, forcing the 5k-row batch UPDATEs added by
  # PR #6388 into whole-table join plans (~7s per batch instead of PK lookups).
  # The planner guard belongs only on the set-based involved_warehouse_scope
  # statements PR #5162 originally protected. This asserts the observable
  # session state inside the block; re-wrapping the whole phase turns it red.
  let(:data_source) { GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp) }
  let(:loader_log) do
    HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: data_source.id, status: :loaded, version: '2026')
  end
  let(:importer) { described_class.new(loader_id: loader_log.id, data_source_id: data_source.id) }

  describe '#with_sql_log' do
    it 'runs its block with nested-loop joins still available' do
      setting = importer.with_sql_log(:nestloop_check, GrdaWarehouse::Hud::Client) do
        GrdaWarehouseBase.connection.select_value('SHOW enable_nestloop')
      end

      expect(setting).to eq('on')
    end
  end
end
