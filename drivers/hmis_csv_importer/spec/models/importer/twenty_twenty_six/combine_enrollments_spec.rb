###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Combine Enrollments', type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
    data_source = create(:unversioned_combined_enrollments_ds)

    create(:unversioned_combined_enrollment_project, data_source_id: data_source.id)

    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/combine_enrollments',
      data_source: data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
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

RSpec.describe 'Combine Enrollments when a later import changes the PersonalID', type: :model do
  fixture_path = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/combine_enrollments'

  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
    data_source = create(:unversioned_combined_enrollments_ds)
    create(:unversioned_combined_enrollment_project, data_source_id: data_source.id)

    import_args = { data_source: data_source, version: 'AutoMigrate', run_jobs: false, stop_version: '2026' }
    import_hmis_csv_fixture(fixture_path, **import_args)

    # Same enrollments and exits, but client C-1 is now identified as C-1-REKEYED
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(fixture_path, 'source'), File.join(dir, 'source'))
      Dir.glob(File.join(dir, 'source', '*.csv')).each do |file|
        File.write(file, File.read(file).gsub(/\bC-1\b/, 'C-1-REKEYED'))
      end
      import_hmis_csv_fixture(dir, **import_args)
    end
  end

  it 'does not keep aggregated enrollments under the superseded PersonalID' do
    aggregated = HmisCsvImporter::Aggregated::Enrollment
    expect(aggregated.where(PersonalID: 'C-1')).to be_empty
    expect(aggregated.group(:EnrollmentID).having('COUNT(*) > 1').count).to be_empty
  end

  it 'still merges enrollments' do
    expect(GrdaWarehouse::Hud::Enrollment.count).to eq(10)
  end

  it 'still imports the exits' do
    expect(GrdaWarehouse::Hud::Exit.count).to eq(9)
  end
end
