###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Clean Up Move In Dates', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    it 'Has 8 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(8)
    end

    it 'Has 5 exits' do
      expect(GrdaWarehouse::Hud::Exit.count).to eq(5)
    end

    it 'Has 8 enrollments with move in dates' do
      expect(GrdaWarehouse::Hud::Enrollment.where.not(MoveInDate: nil).count).to eq(8)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    it 'Has 8 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(8)
    end

    it 'Has 5 exits' do
      expect(GrdaWarehouse::Hud::Exit.count).to eq(5)
    end

    it 'Has 5 enrollments with move in dates' do
      expect(GrdaWarehouse::Hud::Enrollment.where.not(MoveInDate: nil).count).to eq(5)
    end

    it 'Has no move in dates before the enrollment date' do
      e_t = GrdaWarehouse::Hud::Enrollment.arel_table
      expect(GrdaWarehouse::Hud::Enrollment.where(e_t[:MoveInDate].lt(Date.parse('2020-01-01'))).count).to eq(0)
    end

    it 'Has no move in dates after the exit date' do
      e_t = GrdaWarehouse::Hud::Enrollment.arel_table
      expect(GrdaWarehouse::Hud::Enrollment.joins(:exit).where(e_t[:MoveInDate].gt(Date.parse('2020-01-03'))).count).to eq(0)
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    @data_source = if with_cleanup
      create(:importer_cleanup_move_ins_ds)
    else
      create(:importer_dont_cleanup_ds)
    end
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/cleanup_move_ins',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end
