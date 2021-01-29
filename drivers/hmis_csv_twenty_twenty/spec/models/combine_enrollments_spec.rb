###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Combine Enrollments', type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/combine_enrollments'

    @data_source = create(:combined_enrollments_ds)
    @project = create(:combined_enrollment_project, data_source_id: @data_source.id)

    source_file_path = File.join(file_path, 'source')
    @import_path = File.join(file_path, @data_source.id.to_s)
    FileUtils.cp_r(source_file_path, @import_path)

    @loader = HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: @import_path,
      data_source_id: @data_source.id,
      remove_files: false,
    )
    @loader.load!
    @loader.import!
  end

  after(:all) do
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!

    FileUtils.rm_rf(@import_path)
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
