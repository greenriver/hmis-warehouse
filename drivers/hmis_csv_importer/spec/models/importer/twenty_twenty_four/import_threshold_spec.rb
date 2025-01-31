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
        FactoryBot.create(:notification_configuration_import_threshold, :error_count_notification_event, user: @user, source: threshold)

        # move to a time contemporaneous with the incoming data (this may not always be necessary)
        travel_to Time.local(2020, 1, 1) do
          @loader = import_hmis_csv_fixture(
            'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/loader_errors',
            data_source: @data_source,
            version: 'AutoMigrate',
            run_jobs: false,
          )
        end
      end

      after(:all) do
        HmisCsvImporter::Utility.clear!
        GrdaWarehouse::Utility.clear!
      end

      it 'pauses the import when there are issues' do
        expect(@loader.importer_log.status).to eq('paused')
      end

      it 'enqueues a message' do
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to be >= 1
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.map { |j| j[:job] }).to include(ActionMailer::MailDeliveryJob)
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

      after(:all) do
        HmisCsvImporter::Utility.clear!
        GrdaWarehouse::Utility.clear!
      end

      it 'does not pause the import when there are issues' do
        expect(@loader.importer_log.status).to eq('complete')
      end
    end
  end
end
