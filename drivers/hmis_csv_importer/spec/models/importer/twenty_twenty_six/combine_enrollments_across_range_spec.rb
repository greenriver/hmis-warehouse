###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Combine Enrollments across the export range start', type: :model do
  fixture_root = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six'

  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
    @data_source = create(:unversioned_combined_enrollments_ds)
    create(:unversioned_combined_enrollment_project, data_source_id: @data_source.id)
    import_hmis_csv_fixture(
      "#{fixture_root}/combine_enrollments_across_range_initial",
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end

  after(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
  end

  def live_exits
    GrdaWarehouse::Hud::Exit.pluck(:EnrollmentID, :ExitID)
  end

  it 'stores one combined exit per group from the initial file' do
    expect(live_exits).to contain_exactly(['N-1', 'XN-2'], ['M-1', 'XM-2'])
  end

  # N-4 is not contiguous with N-3, so the N-1 group closes before the last C-1 enrollment
  describe 'after a 2023 import that extends the C-1 group and adds a later stay' do
    before(:all) do
      import_hmis_csv_fixture(
        "#{fixture_root}/combine_enrollments_across_range_update",
        data_source: @data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end

    it 'replaces the head enrollment exit and leaves groups outside the range alone' do
      expect(live_exits).to contain_exactly(['N-1', 'XN-3'], ['N-4', 'XN-4'], ['M-1', 'XM-2'])
    end

    describe 'and the same file again' do
      before(:all) do
        import_hmis_csv_fixture(
          "#{fixture_root}/combine_enrollments_across_range_update",
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'keeps the head enrollment and its exit live' do
        expect(GrdaWarehouse::Hud::Enrollment.pluck(:EnrollmentID)).to contain_exactly('N-1', 'N-4', 'M-1')
        expect(live_exits).to contain_exactly(['N-1', 'XN-3'], ['N-4', 'XN-4'], ['M-1', 'XM-2'])
      end
    end
  end
end
