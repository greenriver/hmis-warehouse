###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  describe 'Force Assessment Prioritization status' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = create(:importer_force_prioritized_placement_status)
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/forced_prioritization_placement_status',
        data_source: @data_source,
        version: 'AutoMigrate',
        deidentified: true,
        run_jobs: false,
      )
    end

    it 'all assessments will have prioritization status set to 1' do
      GrdaWarehouse::Hud::Assessment.all.each do |assessment|
        expect(assessment.PrioritizationStatus).to eq(1)
      end
    end
  end
end
