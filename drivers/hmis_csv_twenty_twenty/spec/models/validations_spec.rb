require 'rails_helper'

RSpec.describe 'Combine Enrollments', type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/enrollment_validation_files'

    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)

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
    expect(GrdaWarehouse::Hud::Client.count).to eq(3)
  end

  it 'has two entry after exit validation errors' do
    expect(HmisCsvValidation::EntryAfterExit.count).to eq(2)
  end
end
