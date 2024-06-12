###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvImporter::MarkExpiredJob, type: :model do
  let(:data_source) do
    GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
  end

  def import_records(run_at:)
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

  def run_job(retain_all_records_after:, retained_imports:)
    HmisCsvImporter::MarkExpiredJob.new.perform(
      data_source_id: data_source.id,
      retain_all_records_after: retain_all_records_after,
      retained_imports: retained_imports,
    )
  end

  def loader_records
    HmisCsvTwentyTwentyFour::Loader::Organization
  end

  describe 'with 3 daily imports' do
    let(:now) { DateTime.current }
    let(:run_times) do
      time = now - 1.minute
      [time - 2.days, time - 1.days, time]
    end

    before(:each) do
      run_times.each { |run_time| import_records(run_at: run_time) }
    end

    it 'has expected number of initial records' do
      expect(loader_records.count).to eq(3)
    end

    it 'retains records within period' do
      expect do
        run_job(retain_all_records_after: run_times[1] - 1.minute, retained_imports: 1)
      end.to change { loader_records.where(expired: true).count }.to(1)
    end

    it 'retains only the last X records' do
      expect do
        run_job(retain_all_records_after: now, retained_imports: 1)
      end.to change { loader_records.where(expired: true).count }.to(2)
    end
  end
end
