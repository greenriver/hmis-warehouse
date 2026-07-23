###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'process_existing sub-step timing', type: :model do
  # Test design: Tier 2 — per-file sub-step timings are how a slow
  # process_existing gets attributed to mark_unchanged vs mark_incoming_older
  # vs apply_updates (issue 9211). Real double import: the second run
  # reconciles genuinely unchanged rows, so the timings are recorded on the
  # pass that did the work, alongside the counts proving that pass ran.
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    @data_source = GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp)
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
    @summary = HmisCsvImporter::Importer::ImporterLog.order(:id).last.summary
  end

  after(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  it 'reconciles re-imported rows as unchanged' do
    expect(@summary['Client.csv']['unchanged']).to be > 0
  end

  it 'records mark_unchanged timing per file' do
    client_summary = @summary['Client.csv']
    expect(client_summary['unchanged_secs']).to be_a(Float)
    expect(client_summary['unchanged_secs']).to be >= 0
  end

  it 'records mark_incoming_older timing per file' do
    client_summary = @summary['Client.csv']
    expect(client_summary['older_secs']).to be_a(Float)
    expect(client_summary['older_secs']).to be >= 0
  end

  it 'records sub-step timings for every importable file with staged rows' do
    files_with_rows = @summary.select { |_file, info| info['pre_processed'].to_i.positive? }.keys
    expect(files_with_rows).to include('Client.csv', 'Enrollment.csv', 'Disabilities.csv')
    files_with_rows.each do |file|
      expect(@summary[file]).to have_key('unchanged_secs'), "expected #{file} to record unchanged_secs"
      expect(@summary[file]).to have_key('older_secs'), "expected #{file} to record older_secs"
    end
  end
end
