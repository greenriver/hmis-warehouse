###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::ImportThreshold, type: :model do
  describe 'when import thresholds are present' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      @data_source = GrdaWarehouse::DataSource.where(
        name: 'Green River',
        short_name: 'GR',
        source_type: :sftp,
      ).first_or_create!
      GrdaWarehouse::ImportThreshold.create(
        data_source_id: @data_source.id,
        error_count_min_threshold: 0,
        error_percent_threshold: 0,
        pause_on_error_threshold: true,
      )
      travel_to Time.local(2020, 1, 1) do
        @loader = import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/loader_errors',
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
        )
      end
    end

    it 'pauses the import when there are issues' do
      expect(@loader.importer_log.status).to eq('paused')
    end
  end

  describe 'when import thresholds are not present' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      travel_to Time.local(2020, 1, 1) do
        @loader = import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/loader_errors',
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
        )
      end
    end

    it 'does not pause the import when there are issues' do
      expect(@loader.importer_log.status).to eq('complete')
    end
  end
end
