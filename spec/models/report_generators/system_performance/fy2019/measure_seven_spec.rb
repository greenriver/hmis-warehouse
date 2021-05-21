require 'rails_helper'

# NOTE: 6 mirrors measure 2, but we've converted all ES to SH

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureSeven, type: :model do
  let!(:all_hud_reports_user_role) { create :can_view_all_hud_reports }
  let!(:user) { create :user, roles: [all_hud_reports_user_role] }
  let!(:report) { create :spm_measure_seven_fy2019 }
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

  let(:measure) { ReportGenerators::SystemPerformance::Fy2019::MeasureSeven.new({}) }

  before(:all) do
    @delete_later = []
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    file_path = 'spec/fixtures/files/system_performance/measure_seven'
    import(file_path, @data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    AccessGroup.maintain_system_groups

    Delayed::Worker.new.work_off(2)
  end

  after(:all) do
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    cleanup_files
    Delayed::Job.delete_all
  end

  before(:each) do
    user.access_groups = AccessGroup.all
    measure.run!
    report_result.reload
  end

  it 'counts 2 leavers from SO' do
    expect(report_result.results['sevena1_c2']['value']).to eq(2)
  end

  it 'counts 1 leaver from SO destination permanent' do
    expect(report_result.results['sevena1_c3']['value']).to eq(1)
  end

  it 'counts 1 leaver from SO destination temporary' do
    expect(report_result.results['sevena1_c4']['value']).to eq(1)
  end

  it 'counts 3 clients exiting from ES, SH, TH, and PH-RRH who exited, plus persons in other PH (no move-in dates)' do
    expect(report_result.results['sevenb1_c2']['value']).to eq(3)
  end

  it 'counts 1 client exiting to a permanent destination' do
    expect(report_result.results['sevenb1_c3']['value']).to eq(1)
  end

  it 'counts 1 client in PH with move-in date' do
    expect(report_result.results['sevenb2_c2']['value']).to eq(1)
  end

  it 'counts 1 client exiting to a permanent destination' do
    expect(report_result.results['sevenb2_c3']['value']).to eq(1)
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
