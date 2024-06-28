###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.shared_context 'HmisCsvImporter cleanup context' do
  let(:now) { DateTime.current }

  let(:data_source) do
    GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
  end

  def import_csv_records(run_at:)
    Timecop.freeze(run_at) do
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/allowed_projects',
        version: 'AutoMigrate',
        data_source: data_source,
        run_jobs: false,
        allowed_projects: true,
      )
    end
  end
end

RSpec.shared_context 'HmisCsvImporter cleanup record expiration' do
  describe 'with 3 daily imports' do
    let(:run_times) do
      time = now - 1.minute
      [time - 2.days, time - 1.days, time]
    end

    before(:each) do
      run_times.each { |run_time| import_csv_records(run_at: run_time) }
    end

    it 'retains records within period' do
      expect do
        run_job(retain_after_date: run_times[1] - 1.minute, retain_item_count: 1)
      end.to change { records.where(expired: true).count }.from(0).to(1).
        and change { records.where(expired: false).count }.from(0).to(2)
    end

    it 'retains only the last X records' do
      expect do
        run_job(retain_after_date: now, retain_item_count: 1)
      end.to change { records.where(expired: true).count }.from(0).to(2).
        and change { records.where(expired: false).count }.from(0).to(1)
    end
  end
end
