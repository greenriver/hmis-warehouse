###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Export A (subset) ends at 2016-12-15 (its newest DateUpdated).
# Export B (subset_later_export) is the same data with a later ExportEndDate and one Organization
# DateUpdated moved to 2017-12-30, so it ends at 2017-12-30. Enrollment 557331 is open in both.
RSpec.describe 'Import coverage end date for open enrollments', type: :model do
  fixture_root = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six'
  export_a_path = "#{fixture_root}/enrollment_test_files_subset"
  export_b_path = "#{fixture_root}/enrollment_test_files_subset_later_export"
  export_a_id = '31a77b417911747e41ef9936f9a4b657'
  export_b_id = 'later-export-id'
  export_a_end = Date.new(2016, 12, 15)
  export_b_end = Date.new(2017, 12, 30)

  def run_import(path)
    import_hmis_csv_fixture(path, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
  end

  def effective_end_dates
    GrdaWarehouse::Hud::Export.pluck(:ExportID, :effective_export_end_date).to_h
  end

  def open_enrollment
    GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331')
  end

  def service_history_enrollment
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(open_enrollment.id)
  end

  def snapshot
    {
      effective: effective_end_dates,
      export_id: open_enrollment.ExportID,
      coverage: open_enrollment.import_coverage_end_date,
      build_until: service_history_enrollment.build_until,
    }
  end

  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    run_import(export_a_path)
    @after_a = snapshot
    travel 1.day
    run_import(export_b_path)
    @after_b = snapshot
    travel 1.day
    run_import(export_a_path)
    @after_a_again = snapshot
    # An import that fails during ingest leaves its Export row without an effective_export_end_date.
    later_export = GrdaWarehouse::Hud::Export.find_by(ExportID: export_b_id)
    later_export.update_column(:effective_export_end_date, nil)
    @later_export_unfinished = snapshot
    later_export.update_column(:effective_export_end_date, export_b_end)
    HmisCsvTwentyTwentySix::Importer::Enrollment.where(EnrollmentID: '557331').delete_all
    @without_staging = snapshot
  end

  after(:all) do
    travel_back
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  describe 'effective_export_end_date' do
    it 'is set on each export from its own import' do
      expect(@after_b[:effective]).to eq(export_a_id => export_a_end, export_b_id => export_b_end)
    end

    it 'is not moved onto the newer export when an older export is imported again' do
      expect(@after_a_again[:effective]).to eq(export_a_id => export_a_end, export_b_id => export_b_end)
    end
  end

  describe 'Enrollment#import_coverage_end_date' do
    it 'is the end of the only export that included the enrollment' do
      expect(@after_a[:coverage]).to eq(export_a_end)
    end

    it 'moves to the later export even though the unchanged enrollment keeps the earlier ExportID' do
      expect(@after_b.slice(:coverage, :export_id)).to eq(coverage: export_b_end, export_id: export_a_id)
    end

    it 'stays at the later export when an older export is imported again' do
      expect(@after_a_again[:coverage]).to eq(export_b_end)
    end

    it 'ignores an export whose ingest did not finish' do
      expect(@later_export_unfinished[:coverage]).to eq(export_a_end)
    end

    it 'is nil when the enrollment has no 2026 staging rows' do
      expect(@without_staging[:coverage]).to be_nil
    end
  end

  describe 'ServiceHistory::Enrollment#build_until for an open enrollment' do
    it 'follows the later export' do
      expect([@after_a[:build_until], @after_b[:build_until], @after_a_again[:build_until]]).to eq([export_a_end, export_b_end, export_b_end])
    end

    it "falls back to the enrollment's own export when it has no staging rows" do
      expect(@without_staging[:build_until]).to eq(export_a_end)
    end

    it 'uses the current date for an Open Path HMIS data source' do
      enrollment = service_history_enrollment
      allow(enrollment.data_source).to receive(:hmis?).and_return(true)
      expect(enrollment.build_until).to eq(Date.current)
    end
  end
end
