require 'rails_helper'

RSpec.describe ReportGenerators::CeApr::Fy2020::QuestionFour, type: :model do
  let!(:super_user_role) { create :can_edit_anything_super_user }
  let(:question) do
    ReportGenerators::CeApr::Fy2020::QuestionFour.new(
      ReportGenerators::CeApr::Fy2020::Generator.new(
        user: create(:user, roles: [super_user_role]),
        start_date: Date.yesterday,
        end_date: Date.today,
        project_ids: [1, 2],
      ),
    )
  end

  describe 'Question Four' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      setup('spec/fixtures/files/ce_apr/question_four')
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_files
      Delayed::Job.delete_all
    end

    before(:each) do
      question.run!
    end

    it 'contains 2 projects in Q4' do
      q4 = question.report.cell('Q4', nil)
      expect(q4.metadata.size).to eq(2)
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

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end
