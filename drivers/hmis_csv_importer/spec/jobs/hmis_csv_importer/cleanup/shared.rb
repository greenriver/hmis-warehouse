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

# imports are retained with the following logic
# 1. Any imports newer than retain_after_date are kept
# 2. Any imports older than retain_after_date but within the last retain_item_count are kept
# 3. If no imports are newer than retain_after_date, the latest import is kept PLUS retain_item_count imports
# TODO: these don't follow the above logic currently
RSpec.shared_context 'HmisCsvImporter cleanup record expiration' do
  describe 'with 3 daily imports' do
    let(:run_times) do
      5.times.map { |day| now - day.days }.reverse
    end

    before(:each) do
      run_times.each { |run_time| import_csv_records(run_at: run_time) }
    end

    it 'deletes at most max_per_run records' do
      max_per_run = 2
      expect do
        run_job(retain_after_date: now, retain_item_count: 1, max_per_run: max_per_run, batch_size: max_per_run + 1)
      end.to change { records.count }.from(5).to(3)
    end

    it 'retains records within period' do
      expect do
        run_job(retain_after_date: run_times[-2] - 1.minute, retain_item_count: 0)
      end.to change { records.count }.from(5).to(2)
    end

    it 'retains only the last X records' do
      expect do
        run_job(retain_after_date: now, retain_item_count: 1)
      end.to change { records.count }.from(5).to(1)
    end

    it 'retains all records when retain_item_count is higher than total records' do
      expect do
        run_job(retain_after_date: now, retain_item_count: 6)
      end.not_to(change { records.count })
    end

    it 'does not delete records in dry run mode' do
      expect do
        run_job(retain_after_date: now, retain_item_count: 1, dry_run: true)
      end.not_to(change { records.count })
    end
  end

  it 'handles case with no records' do
    expect do
      run_job(retain_after_date: now, retain_item_count: 1)
    end.not_to(change { records.count })
  end
end
