###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Which warehouse rows an import soft-deletes, in situations where a row's membership in
# the pending set and its membership in the live involved scope can disagree.
RSpec.describe 'HUD CSV import pending deletions', type: :model do
  fixture_root = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six'
  full = "#{fixture_root}/enrollment_test_files"
  subset = "#{fixture_root}/enrollment_test_files_subset"

  def run_import(path)
    import_hmis_csv_fixture(path, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
  end

  def reset_warehouse
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  after(:all) { reset_warehouse }

  describe 'an in-scope row whose staging row is not importable' do
    before(:all) do
      reset_warehouse
      run_import(full)
      # Make staging row 557890 non-importable for the second import only.
      RSpec::Mocks.with_temporary_scope do
        original = HmisCsvImporter::Importer::Importer.instance_method(:ingest!)
        allow_any_instance_of(HmisCsvImporter::Importer::Importer).to receive(:ingest!) do |importer|
          HmisCsvTwentyTwentySix.importable_file_class('Enrollment').
            where(importer_log_id: importer.importer_log.id, EnrollmentID: '557890').
            update_all(should_import: false)
          original.bind_call(importer)
        end
        run_import(subset)
      end
    end

    it 'soft-deletes the row' do
      expect(GrdaWarehouse::Hud::Enrollment.only_deleted.pluck(:EnrollmentID)).to include('557890')
    end

    it 'keeps the importable in-scope row and the out-of-scope row' do
      expect(GrdaWarehouse::Hud::Enrollment.pluck(:EnrollmentID)).to contain_exactly('557331', '622377')
    end
  end

  # Pins what main does today: children drop out of the live involved scope once the enrollment
  # is soft-deleted, so the sweep never reaches them.
  describe 'children of an enrollment removed by the import' do
    before(:all) do
      reset_warehouse
      run_import("#{fixture_root}/enrollment_test_files_with_children")
      run_import("#{fixture_root}/enrollment_test_files_with_children_subset")
    end

    it 'soft-deletes the enrollment' do
      expect(GrdaWarehouse::Hud::Enrollment.only_deleted.pluck(:EnrollmentID)).to eq(['559123'])
    end

    it 'currently leaves its Services row live (existing behavior, not a requirement)' do
      expect(GrdaWarehouse::Hud::Service.where(ServicesID: '90000001').count).to eq(1)
    end

    it 'currently leaves its CurrentLivingSituation row live (existing behavior, not a requirement)' do
      expect(GrdaWarehouse::Hud::CurrentLivingSituation.where(CurrentLivingSitID: '90000002').count).to eq(1)
    end
  end

  # Pins the outcome only. The Services also leave the live involved scope when the exit
  # lands, so they survive regardless of whether the upsert removes them from the pending set.
  describe 'a pending Service that the import treats as new' do
    before(:all) do
      reset_warehouse
      run_import(full)
      @service_ids = GrdaWarehouse::Hud::Service.where(EnrollmentID: '557331').pluck(:ServicesID)
      Dir.mktmpdir do |dir|
        FileUtils.cp_r(full, dir)
        copied = File.join(dir, File.basename(full))
        # 557331 now exits before the export start, so it and its Services leave the involved scope
        File.open(File.join(copied, 'source', 'Exit.csv'), 'a') do |file|
          file.write(File.readlines(File.join(full, 'source', 'Exit.csv')).last.
            sub('429936,622377,', '99000001,557331,').
            sub('2015-11-07', '2016-01-01'))
        end
        run_import(copied)
      end
    end

    it 'had Services to protect' do
      expect(@service_ids.size).to eq(16)
    end

    it 'does not soft-delete the Services' do
      expect(GrdaWarehouse::Hud::Service.where(ServicesID: @service_ids).count).to eq(16)
    end

    it 'does not soft-delete the enrollment' do
      expect(GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: '557331').count).to eq(1)
    end
  end

  # With validations off, only a database error rejects a row. A batch upsert that fails is retried
  # row by row; the rejected row must stay out of the written set so the sweep soft-deletes it.
  # Runs in before(:all) so the first database error does not abort a surrounding transaction.
  describe 'an in-scope row whose update fails to write' do
    before(:all) do
      reset_warehouse
      run_import(full)
      RSpec::Mocks.with_temporary_scope do
        original = HmisCsvImporter::Importer::Importer.instance_method(:ingest!)
        allow_any_instance_of(HmisCsvImporter::Importer::Importer).to receive(:ingest!) do |importer|
          staging = HmisCsvTwentyTwentySix.importable_file_class('Enrollment').where(importer_log_id: importer.importer_log.id)
          # UserID is varchar(100) in the warehouse and unbounded in staging
          staging.where(EnrollmentID: '557890').update_all(UserID: 'x' * 101, source_hash: 'forced-change')
          staging.where(EnrollmentID: '557331').update_all(UserID: 'changed', source_hash: 'forced-change-ok')
          original.bind_call(importer)
        end
        @second_log = run_import(full).importer_log
      end
    end

    it 'soft-deletes the row that failed to write' do
      expect(GrdaWarehouse::Hud::Enrollment.only_deleted.pluck(:EnrollmentID)).to include('557890')
    end

    it 'still updates the sibling row in the same batch' do
      enrollment = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331')
      expect(enrollment.UserID).to eq('changed')
    end

    it 'records exactly one import error, for the Enrollment table' do
      errors = HmisCsvImporter::Importer::ImportError.where(importer_log_id: @second_log.id)
      expect(errors.pluck(:source_type)).to eq(['GrdaWarehouse::Hud::Enrollment'])
    end
  end

  describe 'an import that fails during ingest' do
    before(:all) { reset_warehouse }

    it 'drops the pending-set temp tables and propagates the error' do
      tables_at_failure = nil
      allow_any_instance_of(HmisCsvImporter::Importer::Importer).to receive(:remove_pending_deletes) do
        tables_at_failure = pending_temp_table_names
        raise 'ingest failed'
      end

      expect { run_import(full) }.to raise_error(RuntimeError, 'ingest failed')
      expect(tables_at_failure).not_to be_empty
      expect(pending_temp_table_names).to eq([])
    end
  end
end
