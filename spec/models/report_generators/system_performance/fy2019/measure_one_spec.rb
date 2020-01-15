require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureOne, type: :model do
  let!(:super_user_role) { create :can_edit_anything_super_user }
  let!(:user) { create :user, roles: [super_user_role] }
  let!(:report) { create :spm_measure_one_fy2019 }
  let!(:report_result) do
    create :report_result,
           report: report,
           user: user,
           options: {
             report_start: Date.parse('2016-1-1'),
             report_end: Date.parse('2016-12-31'),
             project_group_ids: [],
             project_id: [],
           }
  end

  let!(:measure) { ReportGenerators::SystemPerformance::Fy2019::MeasureOne.new({}) }

  describe 'measure one example' do
    before(:all) do
      setup('spec/fixtures/files/system_performance/measure_one')
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

    it 'finds one 1a client' do
      expect(report_result.results['onea_c2']['value']).to eq(1)
    end

    it 'reports 5 months 1a days' do
      days = (Date.parse('2016-4-30') - Date.parse('2016-2-1')).to_i +
        (Date.parse('2016-10-31') - Date.parse('2016-9-1')).to_i
      expect(report_result.results['onea_e2']['value']).to eq(days)
    end

    it 'finds one 1b client' do
      expect(report_result.results['oneb_c2']['value']).to eq(1)
    end

    it 'reports 13 months 1b days' do
      days = (Date.parse('2016-4-30') - Date.parse('2015-8-1')).to_i +
        (Date.parse('2016-10-31') - Date.parse('2016-7-1')).to_i
      expect(report_result.results['oneb_e2']['value']).to eq(days)
    end
  end

  describe 'measure one additional tests' do
    before(:all) do
      setup('spec/fixtures/files/system_performance/measure_one_additional')
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

    it 'excludes client 1 (1a)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '1')
      expect(report_result.support['onea_c2']['support']['counts'].select { |c| c[0] == client.id }).to be_empty
    end

    it 'counts 27 days for client 2 (1b)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '2')
      expect(report_result.support['onea_c2']['support']['counts'].select { |c| c[0] == client.id }.first[1]).to eq(27)
    end

    it 'counts 27 days for client 3 (1c)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '3')
      expect(report_result.support['onea_c2']['support']['counts'].select { |c| c[0] == client.id }.first[1]).to eq(27)
    end

    it 'counts 1 days for client 4 (1d)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '4')
      expect(report_result.support['onea_c2']['support']['counts'].select { |c| c[0] == client.id }.first[1]).to eq(1)
    end

    it 'counts 28 days for client 5 (1e)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '5')
      expect(report_result.support['onea_c2']['support']['counts'].select { |c| c[0] == client.id }.first[1]).to eq(28)
    end

    it 'client 6 has no stays (1f)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '6')
      expect(report_result.support['onea_c2']['support']['counts'].select { |c| c[0] == client.id }.first[1]).to eq(0)
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
