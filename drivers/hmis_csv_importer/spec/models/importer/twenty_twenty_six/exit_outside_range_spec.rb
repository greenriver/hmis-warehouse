###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HMIS CSV import of exits outside the export range', type: :model do
  fixture_root = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six'

  def import(dir)
    import_hmis_csv_fixture(dir, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
  end

  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import("#{fixture_root}/exit_outside_range_initial")
  end

  after(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  it 'imports every exit live from the initial file' do
    expect(GrdaWarehouse::Hud::Exit.pluck(:ExitID)).to contain_exactly('X-A', 'X-B', 'X-C', 'X-D', 'X-E', 'X-F', 'X-G1', 'X-H')
  end

  describe 'after a reporting-period import for 2023-2024' do
    before(:all) do
      GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: ['E-A', 'E-B']).update_all(processed_as: 'stale')
      import("#{fixture_root}/exit_outside_range_update")
    end

    # X-C and X-H are off-spec input; see the 'with rows a reporting-period export never contains' context
    it 'soft-deletes exactly the exits the import is authoritative for and did not send' do
      expect(GrdaWarehouse::Hud::Exit.only_deleted.pluck(:ExitID)).to contain_exactly('X-A', 'X-D', 'X-E', 'X-G1')
    end

    it 'keeps exits of enrollments not in the file, exits sent in the file, and exits after ExportEndDate' do
      expect(GrdaWarehouse::Hud::Exit.pluck(:ExitID)).to contain_exactly('X-B', 'X-C', 'X-F', 'X-G2', 'X-H')
    end

    # These rows break the FY2026 CSV spec's reporting-period rules. The examples record
    # what the importer does with them; they are not spec requirements.
    context 'with rows a reporting-period export never contains' do
      it 'keeps a pre-range exit that the file sends for an enrollment it sends' do
        expect(GrdaWarehouse::Hud::Exit.with_deleted.where(ExitID: 'X-C').pluck(:DateDeleted)).to eq([nil])
      end

      it 'updates an exit dated after ExportEndDate in place when the file sends it' do
        rows = GrdaWarehouse::Hud::Exit.with_deleted.where(ExitID: 'X-H')
        expect(rows.pluck(:Destination, :DateDeleted)).to eq([[116, nil]])
      end
    end

    # Pass 1 upserts every in-file enrollment with processed_as nil, so E-A can't isolate the
    # new step's reset; E-B catches a reset that reaches enrollments outside the file.
    it 'clears processed_as on enrollments in the file and leaves the rest alone' do
      processed = GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: ['E-A', 'E-B']).pluck(:EnrollmentID, :processed_as).to_h
      expect(processed).to eq('E-A' => nil, 'E-B' => 'stale')
    end

    it 'counts every removed exit in the import summary' do
      expect(HmisCsvImporter::Importer::ImporterLog.last.summary['Exit.csv']['removed']).to eq(4)
    end

    it 'leaves no exits pending deletion' do
      expect(GrdaWarehouse::Hud::Exit.with_deleted.where.not(pending_date_deleted: nil).count).to eq(0)
    end
  end
end
