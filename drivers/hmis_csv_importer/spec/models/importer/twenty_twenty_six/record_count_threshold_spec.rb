###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  describe 'pauses when record-count thresholds are exceeded' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      # First import establishes baseline data in the warehouse
      travel_to Time.local(2017, 10, 3) do
        @data_source = GrdaWarehouse::DataSource.where(
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
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      # Now configure aggressive record-count thresholds that will trigger
      # on the second (identical) import. The second import sees all existing
      # warehouse rows as "existing" and all incoming rows as "new" until
      # reconciliation, so the precalculated added count is non-zero on a
      # first-ever import against an empty warehouse for that scope.
      threshold = FactoryBot.create(
        :import_threshold,
        data_source: @data_source,
        pause_on_error_threshold: true,
        pause_on_record_count_threshold: true,
        error_percent_threshold: 1,
        error_count_min_threshold: 1,
        record_count_change_min_threshold: 1,
        record_count_change_percent_threshold: 1,
      )
      @user = FactoryBot.create(:user)
      FactoryBot.create(:notification_configuration_import_threshold, :record_count_change_notification_event, user: @user, source: threshold)

      # Second import with thresholds active
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

    it 'exercises precalculate_change_counts and populates the summary' do
      summary = @loader.importer_log.summary
      files_with_counts = summary.select { |_, data| data.key?('added') || data.key?('removed') }
      expect(files_with_counts).to be_present
    end
  end
end
