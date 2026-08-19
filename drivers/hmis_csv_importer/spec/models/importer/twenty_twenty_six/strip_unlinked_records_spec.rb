###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    travel_to Time.local(2020, 1, 1) do
      @loader = import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/strip_unlinked_records',
        data_source: FactoryBot.create(:strip_unlinked_records_ds),
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end
  end

  it 'does not load the enrollment with no matching client' do
    expect(GrdaWarehouse::Hud::Enrollment.count).to eq(1)
    expect(GrdaWarehouse::Hud::Enrollment.first.EnrollmentID).to eq('E-1')
  end

  it 'logs the discarded enrollment' do
    notes = @loader.loader_log.row_processing_notes
    expect(notes.count).to eq(1)
    expect(notes.first.file_name).to eq('Enrollment.csv')
    expect(notes.first.reason).to eq('no_matching_personal_id')
  end
end
