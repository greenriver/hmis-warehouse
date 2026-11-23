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

  describe 'children of an enrollment removed by the import' do
    before(:all) do
      reset_warehouse
      run_import("#{fixture_root}/enrollment_test_files_with_children")
      run_import("#{fixture_root}/enrollment_test_files_with_children_subset")
    end

    it 'soft-deletes the enrollment' do
      expect(GrdaWarehouse::Hud::Enrollment.only_deleted.pluck(:EnrollmentID)).to eq(['559123'])
    end

    it 'leaves its Services row live, because it is no longer in the live involved scope' do
      expect(GrdaWarehouse::Hud::Service.where(ServicesID: '90000001').count).to eq(1)
    end

    it 'leaves its CurrentLivingSituation row live, because it is no longer in the live involved scope' do
      expect(GrdaWarehouse::Hud::CurrentLivingSituation.where(CurrentLivingSitID: '90000002').count).to eq(1)
    end
  end

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
end
