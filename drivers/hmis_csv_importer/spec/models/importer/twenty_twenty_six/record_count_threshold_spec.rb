###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Import record-count change thresholds', type: :model do
  fixture_path = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/enrollment_test_files'

  describe 'precalculate_change_counts executes without error' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      # Nonzero error_percent_threshold makes ever_notify_for_imports? truthy,
      # which gates precalculate_change_counts.  pause_on_error_threshold is
      # false so the import won't pause on error counts.
      threshold = FactoryBot.create(
        :import_threshold,
        pause_on_error_threshold: false,
        error_percent_threshold: 1,
        error_count_min_threshold: 1,
      )
      @data_source = threshold.data_source

      travel_to Time.local(2017, 10, 3) do
        @loader = import_hmis_csv_fixture(
          fixture_path,
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'completes the import successfully' do
      expect(@loader.importer_log.status).to eq('complete')
    end

    it 'populates added counts in the summary' do
      summary = @loader.importer_log.summary
      files_with_adds = summary.select { |_, data| data['added'].to_i.positive? }
      expect(files_with_adds).to be_present
    end
  end

  describe 'pausing on record-count changes' do
    def import_twice_with_threshold(fixture_path, **threshold_attrs)
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      travel_to Time.local(2017, 10, 3) do
        data_source = GrdaWarehouse::DataSource.where(
          name: 'Green River',
          short_name: 'GR',
          source_type: :sftp,
        ).first_or_create!
        GrdaWarehouse::DataSource.where(
          name: 'Warehouse',
          short_name: 'W',
        ).first_or_create!

        import_hmis_csv_fixture(
          fixture_path,
          data_source: data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )

        # Re-importing these fixture files still counts one new Enrollment out of three,
        # which crosses the 1-record / 1% threshold. Blank error thresholds keep error
        # counts from pausing the import.
        FactoryBot.create(
          :import_threshold,
          data_source: data_source,
          error_count_min_threshold: nil,
          error_percent_threshold: nil,
          record_count_change_min_threshold: 1,
          record_count_change_percent_threshold: 1,
          **threshold_attrs,
        )

        import_hmis_csv_fixture(
          fixture_path,
          data_source: data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    context 'when only the record-count pause is enabled' do
      before(:all) do
        @loader = import_twice_with_threshold(
          fixture_path,
          pause_on_record_count_threshold: true,
          pause_on_error_threshold: false,
        )
      end

      it 'pauses the import' do
        expect(@loader.importer_log.status).to eq('paused')
      end
    end

    context 'when only the error pause is enabled' do
      before(:all) do
        @loader = import_twice_with_threshold(
          fixture_path,
          pause_on_record_count_threshold: false,
          pause_on_error_threshold: true,
        )
      end

      it 'completes the import' do
        expect(@loader.importer_log.status).to eq('complete')
      end
    end
  end
end
