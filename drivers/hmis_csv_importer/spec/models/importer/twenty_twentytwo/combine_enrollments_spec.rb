###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Combine Enrollments', type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
    data_source = create(:combined_enrollments_ds)

    create(:combined_enrollment_project, data_source_id: data_source.id)

    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/combine_enrollments',
      data_source: data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end

  it 'includes all clients' do
    expect(GrdaWarehouse::Hud::Client.count).to eq(2)
  end

  it 'merges enrollments' do
    expect(GrdaWarehouse::Hud::Enrollment.count).to eq(10)
  end

  it 'merges exits' do
    expect(GrdaWarehouse::Hud::Exit.count).to eq(9)
  end
end
