###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::ImportThreshold, type: :model do
  describe 'imports with errors' do
    describe 'when import thresholds are present' do
      # Using before all as imports are relatively expensive/time consuming
      before(:all) do
        HmisCsvImporter::Utility.clear!
        GrdaWarehouse::Utility.clear!

        threshold = FactoryBot.create(:import_threshold, pause_on_error_threshold: true)
        @data_source = threshold.data_source
        @user = FactoryBot.create(:user)
        FactoryBot.create(:notification_configuration_import_threshold, :import_error_count_slug, user: @user, source: threshold)

        travel_to Time.local(2020, 1, 1) do
          @loader = import_hmis_csv_fixture(
            'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/loader_errors',
            data_source: @data_source,
            version: 'AutoMigrate',
            run_jobs: false,
          )
        end
        @email = ActionMailer::Base.deliveries.last
      end

      it 'pauses the import when there are issues' do
        expect(@loader.importer_log.status).to eq('paused')
      end

      it 'enqueues a message' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        # expect(enqueued_jobs.size).to eq 1
        # expect(NotifyUser).to have_enqueued_mail(:import_processing).with(@user)
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
end
