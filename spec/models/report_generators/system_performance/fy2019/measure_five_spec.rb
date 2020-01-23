require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureFive, type: :model do
  let!(:super_user_role) { create :can_edit_anything_super_user }
  let!(:user) { create :user, roles: [super_user_role] }
  let!(:report) { create :spm_measure_five_fy2019 }
  let!(:report_result) do
    create :report_result,
           report: report,
           user: user,
           options: {
             report_start: Date.parse('2015-1-1'),
             report_end: Date.parse('2015-12-31'),
             project_group_ids: [],
             project_id: [],
           }
  end

  let(:measure) { ReportGenerators::SystemPerformance::Fy2019::MeasureFive.new({}) }

  before(:all) do
    @delete_later = []
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    file_path = 'spec/fixtures/files/system_performance/measure_five'
    import(file_path, @data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!

    Delayed::Worker.new.work_off(2)
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

  it 'counts 6 clients in 5.1 universe' do
    expect(report_result.results['five1_c2']['value']).to eq(6)
  end

  it 'counts 3 returns in 5.1 universe' do
    expect(report_result.results['five1_c3']['value']).to eq(3)
  end

  it 'counts 8 clients in 5.2 universe' do
    expect(report_result.results['five2_c2']['value']).to eq(8)
  end

  it 'counts 4 clients in 5.2 universe' do
    expect(report_result.results['five2_c3']['value']).to eq(4)
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
