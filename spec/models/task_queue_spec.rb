###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskQueue, '.register_tasks' do
  let(:config) { Rails.application.config }

  before { described_class.register_tasks(config) }

  it 'registers a single importer_log_id/DateUpdated index task' do
    expect(config.queued_tasks.keys).to include(:hmis_csv_2026_importer_log_id_date_updated_index)
  end

  it 'calls ensure_importer_log_id_date_updated_index! on every base FY2026 importer class except Export, sequentially' do
    expected_classes = HmisCsvTwentyTwentySix.base_importable_files_map.except('Export.csv').values.map do |name|
      HmisCsvTwentyTwentySix.data_lake_file_class(name, 'Importer')
    end

    expected_classes.each { |klass| expect(klass).to receive(:ensure_importer_log_id_date_updated_index!) }
    expect(HmisCsvTwentyTwentySix::Importer::Export).not_to receive(:ensure_importer_log_id_date_updated_index!)

    config.queued_tasks[:hmis_csv_2026_importer_log_id_date_updated_index].call
  end
end
