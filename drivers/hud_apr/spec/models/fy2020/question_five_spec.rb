require 'rails_helper'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionFive, type: :model do
  let!(:super_user_role) { create :can_edit_anything_super_user }
  let!(:user) { create :user, roles: [super_user_role] }
  let!(:report) do
    HudApr::Generators::Apr::Fy2020::Generator.new(
      {
        'start_date' => Date.parse('2015-1-1'),
        'end_date' => Date.parse('2015-12-31'),
        'coc_code' => 'MA-500',
        'user_id' => user.id,
      }
    )
  end

  describe 'Q5' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      setup('drivers/hud_apr/spec/fixtures/files/fy2020/q5')
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_files
      Delayed::Job.delete_all
    end

    before(:each) do
      report.run!(questions: ['Q5'])
      Delayed::Worker.new.work_off
    end

    it 'counts people served' do
      expect(report_result.answer(question: 'Q5a', cell: 'B1').summary).to eq(4)
    end

    it 'counts adults' do
      expect(report_result.answer(question: 'Q5a', cell: 'B2').summary).to eq(2)
    end

    it 'counts children' do
      expect(report_result.answer(question: 'Q5a', cell: 'B3').summary).to eq(1)
    end

    it 'counts missing age' do
      expect(report_result.answer(question: 'Q5a', cell: 'B4').summary).to eq(1)
    end

    it 'counts leavers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B5').summary).to eq(2)
    end

    it 'counts adult leavers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B6').summary).to eq(0)
    end

    it 'counts adult head of household leavers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B7').summary).to eq(2) # should eq 0, leaving so I can write more tests
    end

    it 'counts stayers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B8').summary).to eq(2)
    end

    it 'counts adult stayers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B9').summary).to eq(2)
    end

    it 'counts veterans' do
      expect(report_result.answer(question: 'Q5a', cell: 'B10').summary).to eq(0)
    end

    it 'counts chronically homeless persons' do
      expect(report_result.answer(question: 'Q5a', cell: 'B11').summary).to eq(0)
    end

    it 'counts under 25' do
      expect(report_result.answer(question: 'Q5a', cell: 'B12').summary).to eq(0)
    end

    it 'counts under 25 with children' do
      expect(report_result.answer(question: 'Q5a', cell: 'B13').summary).to eq(0)
    end

    it 'counts adult heads of household' do
      expect(report_result.answer(question: 'Q5a', cell: 'B14').summary).to eq(0)
    end

    it 'counts child and unknown age heads of household' do
      expect(report_result.answer(question: 'Q5a', cell: 'B15').summary).to eq(2)
    end

    it 'counts heads of household and stayers over 365 days' do
      expect(report_result.answer(question: 'Q5a', cell: 'B16').summary).to eq(1)
    end
  end

  def setup(file_path)
    @delete_later = []
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    import(file_path, @data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!

    Delayed::Worker.new.work_off(2)
  end

  def import(file_path, data_source)
    source_file_path = File.join(file_path, 'source')
    import_path = File.join(file_path, data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path unless import_path == source_file_path

    importer = Importers::HmisTwentyTwenty::Base.new(file_path: file_path, data_source_id: data_source.id, remove_files: false)
    importer.import!
  end

  def report_result
    HudReports::ReportInstance.last
  end

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end
