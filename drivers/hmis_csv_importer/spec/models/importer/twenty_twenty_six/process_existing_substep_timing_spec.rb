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

  # mark_unchanged is the step that reconciles on this pass, so its timing has to
  # reflect real elapsed work. mark_incoming_older, by contrast, early-returns
  # here: both imports carry the same ExportDate, so most_recent_export_for_ds?
  # treats the incoming export as authoritative. Its timing is still recorded
  # (the step ran, it just had nothing to do), which is why the mapping from step
  # to summary key is proven separately below rather than by magnitude here.
  it 'records elapsed time for the step that did the reconciling' do
    expect(@summary['Client.csv']['unchanged_secs']).to be > 0
  end

  it 'records both sub-step timings for every importable file with staged rows' do
    files_with_rows = @summary.select { |_file, info| info['pre_processed'].to_i.positive? }.keys
    expect(files_with_rows).to include('Client.csv', 'Enrollment.csv', 'Disabilities.csv')
    files_with_rows.each do |file|
      expect(@summary[file]['unchanged_secs']).to be_a(Float), "expected #{file} to record unchanged_secs"
      expect(@summary[file]['older_secs']).to be_a(Float), "expected #{file} to record older_secs"
    end
  end

  # mark_unchanged and mark_incoming_older both accumulate into the shared
  # 'unchanged' summary count, so per-step rates cannot be read back from that
  # key by type. Force a row through mark_incoming_older (incoming DateUpdated
  # older than the warehouse copy, nil warehouse source_hash so the hash
  # comparison cannot match, non-authoritative ExportDate) and assert the rate
  # is attributed from that step's own row count.
  describe 'attributing rates to the step that did the work' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp)
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_initial',
        data_source: @data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
      # Warehouse copy newer than the incoming row, with a nil source_hash so
      # mark_unchanged cannot match; the only path that can keep this row is
      # mark_incoming_older.
      GrdaWarehouse::Hud::Client.first.update_columns(DateUpdated: Time.zone.parse('2035-01-01 12:00').utc, source_hash: nil)
      older_importer = import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_older',
        data_source: @data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
      @older_summary = older_importer.importer_log.summary
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'records a positive older_rps from the rows mark_incoming_older kept' do
      client_summary = @older_summary['Client.csv']
      expect(client_summary['unchanged']).to eq(1) # the older step's row, in the shared tally
      expect(client_summary['older_secs']).to be_a(Float)
      expect(client_summary['older_rps']).to be_a(Float)
      expect(client_summary['older_rps']).to be > 0
    end

    it 'does not attribute the shared tally to the step that did no work' do
      client_summary = @older_summary['Client.csv']
      expect(client_summary).not_to have_key('unchanged_rps')
    end
  end

  # The real-import cases above prove the counts and rates, but not that each
  # timing lands under its own key: both sub-steps finish in milliseconds on a
  # fixture this size, so any assertion on their magnitude would be noise.
  # Injecting a known delay into one step makes the step-to-key mapping
  # falsifiable -- swapping the two Benchmark blocks in process_existing, or
  # timing the wrong call, turns this red.
  describe 'attributing elapsed time to the step that spent it' do
    let(:delay) { 0.25 }

    it 'records the delayed step under its own key and leaves the other step fast' do
      # The incoming export has to be non-authoritative for mark_incoming_older
      # to run at all, which needs a newer export already loaded for the data
      # source. Whether the step matches any row is irrelevant here -- the rates
      # cover that; this example only measures where the elapsed time is filed.
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_initial',
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )

      # There is no seam to inject a collaborator into the importer the loader
      # builds, so the delay is added on the way through: the wrapped call still
      # runs the real step, it just takes a known minimum.
      allow_any_instance_of(HmisCsvImporter::Importer::Importer).
        to receive(:mark_incoming_older).and_wrap_original do |original, klass, file_name|
          sleep(delay) if file_name == 'Client.csv'
          original.call(klass, file_name)
        end

      importer = import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_older',
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )

      client_summary = importer.importer_log.summary['Client.csv']
      expect(client_summary['older_secs']).to be >= delay
      expect(client_summary['unchanged_secs']).to be < delay
    end
  end
end
