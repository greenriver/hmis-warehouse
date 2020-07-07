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
      file_path: file_path,
      data_source_id: @data_source.id,
      remove_files: false,
    )
    @loader.import!
  end

  after(:all) do
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!

    FileUtils.rm_rf(@import_path)
  end

  it 'does nothing' do
  end
end
