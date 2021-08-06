###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Ensure Relationships', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(19)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(19)
    end

    it 'Individual enrollments all have one HoH' do
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-1').RelationshipToHoH).to eq(1)
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    @data_source = if with_cleanup
      create(:ensure_relationships_ds)
    else
      create(:dont_cleanup_ds)
    end
    import_hmis_csv_fixture(
      'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/ensure_relationships',
      data_source: @data_source,
      version: '2020',
      run_jobs: false,
    )
  end
end
