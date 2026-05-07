###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression: in multi-CoC projects, ProjectCleanup previously cleared
# non-HoH EnrollmentCoC values to NULL instead of propagating the HoH's CoC
# to household members. Fixture has a two-CoC project (XX-500, XX-501) with a
# two-person household where only the HoH carries an EnrollmentCoC.
RSpec.describe 'Household EnrollmentCoC propagation in multi-CoC projects', type: :model do
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/household_coc_propagation',
      version: 'AutoMigrate',
      run_jobs: true,
      stop_version: '2026',
    )
  end

  let(:project) { GrdaWarehouse::Hud::Project.find_by(ProjectID: 'proj-1') }
  let(:hoh_enrollment) { GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'enroll-hoh') }
  let(:spouse_enrollment) { GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'enroll-spouse') }

  it 'imports the project with two CoC codes' do
    expect(project.project_cocs.map(&:CoCCode).sort).to eq(['XX-500', 'XX-501'])
  end

  it 'imports both enrollments into the same household' do
    expect(hoh_enrollment).to be_present
    expect(spouse_enrollment).to be_present
    expect(hoh_enrollment.HouseholdID).to eq(spouse_enrollment.HouseholdID)
  end

  it 'preserves the HoH EnrollmentCoC' do
    expect(hoh_enrollment.EnrollmentCoC).to eq('XX-500')
  end

  it 'propagates the HoH EnrollmentCoC to the spouse (the regression case)' do
    expect(spouse_enrollment.EnrollmentCoC).to eq('XX-500')
  end
end
