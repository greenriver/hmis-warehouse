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

  it 'registers an importer_log_id/DateUpdated index task for every base FY2026 importer table except Export' do
    expected_keys = HmisCsvTwentyTwentySix.base_importable_files_map.except('Export.csv').values.map do |name|
      klass = HmisCsvTwentyTwentySix.data_lake_file_class(name, 'Importer')
      :"hmis_csv_2026_importer_log_id_date_updated_index_#{klass.table_name}"
    end

    expect(config.queued_tasks.keys).to include(*expected_keys)
    expect(config.queued_tasks.keys).not_to include(:hmis_csv_2026_importer_log_id_date_updated_index_hmis_2026_exports)
  end

  it 'calls ensure_importer_log_id_date_updated_index! on the corresponding importer class' do
    klass = HmisCsvTwentyTwentySix::Importer::HealthAndDv
    expect(klass).to receive(:ensure_importer_log_id_date_updated_index!)

    config.queued_tasks[:"hmis_csv_2026_importer_log_id_date_updated_index_#{klass.table_name}"].call
  end
end
