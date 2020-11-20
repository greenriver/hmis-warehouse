require 'rails_helper'

RSpec.describe 'Clean Up Move In Dates', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    after(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
    end

    it 'Has 8 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(8)
    end

    it 'Has 5 exits' do
      expect(GrdaWarehouse::Hud::Exit.count).to eq(5)
    end

    it 'Has 8 enrollments with move in dates' do
      expect(GrdaWarehouse::Hud::Enrollment.where.not(MoveInDate: nil).count).to eq(8)
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

    it 'Has 8 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(8)
    end

    it 'Has 5 exits' do
      expect(GrdaWarehouse::Hud::Exit.count).to eq(5)
    end

    it 'Has 5 enrollments with move in dates' do
      expect(GrdaWarehouse::Hud::Enrollment.where.not(MoveInDate: nil).count).to eq(5)
    end

    it 'Has no move in dates before the enrollment date' do
      e_t = GrdaWarehouse::Hud::Enrollment.arel_table
      expect(GrdaWarehouse::Hud::Enrollment.where(e_t[:MoveInDate].lt(Date.parse('2020-01-01'))).count).to eq(0)
    end

    it 'Has no move in dates after the exit date' do
      e_t = GrdaWarehouse::Hud::Enrollment.arel_table
      expect(GrdaWarehouse::Hud::Enrollment.joins(:exit).where(e_t[:MoveInDate].gt(Date.parse('2020-01-03'))).count).to eq(0)
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/cleanup_move_ins'

    @data_source = if with_cleanup
      create(:cleanup_move_ins_ds)
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
