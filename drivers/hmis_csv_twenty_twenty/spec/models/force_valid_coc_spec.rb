require 'rails_helper'

RSpec.describe 'Force Valid CoC Codes', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    after(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
    end

    it 'Has 9 enrollment cocs' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.count).to eq(9)
    end

    it 'Includes invalid CoCCodes' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA5001')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('zz999')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('ma504')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode).compact.count).to eq(9)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    after(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
    end

    it 'Has 9 enrollment cocs' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.count).to eq(9)
    end

    it 'Includes ignores CoCCodes it cannot fix' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode).compact.count).to eq(4)
    end

    it 'Includes corrected CoCCodes' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA-502')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA-503')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA-504')
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/cleanup_move_ins'

    @data_source = if with_cleanup
      create(:force_valid_enrollment_cocs)
    else
      create(:dont_cleanup_ds)
    end

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
end
