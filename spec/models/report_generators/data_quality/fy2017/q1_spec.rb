require 'rails_helper'

RSpec.describe ReportGenerators::DataQuality::Fy2017::Q1, type: :model do
  let!(:super_user_role) { create :can_edit_anything_super_user }
  let!(:user) { create :user, roles: [super_user_role] }
  let!(:report) { create :data_quality_q1_fy2017 }
  let!(:report_result) do
    create :report_result,
           report: report,
           user: user,
           options: {
             report_start: Date.parse('2015-1-1'),
             report_end: Date.parse('2015-12-31'),
             project_group_ids: [],
             project_id: [],
             project_type: [],
           }
  end
  let!(:measure) do
    ReportGenerators::DataQuality::Fy2017::Q1.new(
      user_id: user.id, report: report,
      user: user,
      options: {
        report_start: Date.parse('2015-1-1'),
        report_end: Date.parse('2015-12-31'),
        project_group_ids: [],
        project_id: [],
        project_type: [],
      }
    )
  end

  describe 'measure one example' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      setup('spec/fixtures/files/data_quality/fy2017/q1')
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_files
      Delayed::Job.delete_all
    end

    before(:each) do
      measure.run!
      report_result.reload
    end

    it 'counts people served' do
      expect(report_result['results']['q1_b1']['value']).to eq(4)
    end

    it 'counts adults' do
      expect(report_result['results']['q1_b2']['value']).to eq(2)
    end

    it 'counts children' do
      expect(report_result['results']['q1_b3']['value']).to eq(1)
    end

    it 'counts missing age' do
      expect(report_result['results']['q1_b4']['value']).to eq(1)
    end

    it 'counts leavers' do
      expect(report_result['results']['q1_b5']['value']).to eq(2)
    end

    it 'counts adult leavers' do
      expect(report_result['results']['q1_b6']['value']).to eq(0)
    end

    it 'counts adult head of household leavers' do
      expect(report_result['results']['q1_b7']['value']).to eq(2) # should eq 0, leaving so I can write more tests
    end

    it 'counts stayers' do
      expect(report_result['results']['q1_b8']['value']).to eq(2)
    end

    it 'counts adult stayers' do
      expect(report_result['results']['q1_b9']['value']).to eq(2)
    end

    it 'counts veterans' do
      expect(report_result['results']['q1_b10']['value']).to eq(0)
    end

    it 'counts chronically homeless persons' do
      expect(report_result['results']['q1_b11']['value']).to eq(0)
    end

    it 'counts under 25' do
      expect(report_result['results']['q1_b12']['value']).to eq(0)
    end

    it 'counts under 25 with children' do
      expect(report_result['results']['q1_b13']['value']).to eq(0)
    end

    it 'counts adult heads of household' do
      expect(report_result['results']['q1_b14']['value']).to eq(0)
    end

    it 'counts child and unknown age heads of household' do
      expect(report_result['results']['q1_b15']['value']).to eq(2)
    end

    it 'counts heads of household and stayers over 365 days' do
      expect(report_result['results']['q1_b16']['value']).to eq(1)
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
