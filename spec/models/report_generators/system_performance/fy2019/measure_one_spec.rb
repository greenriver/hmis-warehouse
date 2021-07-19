require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureOne, type: :model do
  let!(:all_hud_reports_user_role) { create :can_view_all_hud_reports }
  let!(:user) { create :user, roles: [all_hud_reports_user_role] }
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
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture('spec/fixtures/files/system_performance/measure_one')
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
      Delayed::Job.delete_all
    end

    before(:each) do
      user.access_groups = AccessGroup.all
      measure.run!
      report_result.reload
    end

    it 'finds one 1a client' do
      expect(report_result.results['onea_c2']['value']).to eq(1)
    end

    it 'reports 5 months 1a days' do
      days = (Date.parse('2016-5-1') - Date.parse('2016-2-1')).to_i +
        (Date.parse('2016-11-1') - Date.parse('2016-9-1')).to_i
      expect(report_result.results['onea_e2']['value']).to eq(days)
    end

    it 'finds one 1b client' do
      expect(report_result.results['oneb_c2']['value']).to eq(1)
    end

    it 'reports 13 months 1b days' do
      days = (Date.parse('2016-5-1') - Date.parse('2015-8-1')).to_i +
        (Date.parse('2016-11-1') - Date.parse('2016-7-1')).to_i
      expect(report_result.results['oneb_e2']['value']).to eq(days)
    end
  end

  describe 'measure one additional tests' do
    before(:all) do
      import_hmis_csv_fixture('spec/fixtures/files/system_performance/measure_one_additional')
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
      Delayed::Job.delete_all
    end

    before(:each) do
      user.access_groups = AccessGroup.all
      measure.run!
      report_result.reload
    end

    it 'excludes client 1 (1a)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '1')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }).to be_empty
    end

    it 'counts 27 days for client 2 (1b)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '2')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(27)
    end

    it 'counts 27 days for client 3 (1c)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '3')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(27)
    end

    it 'counts 1 days for client 4 (1d)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '4')
      # Note 2016 is a leap year, so the client receives 2/28 and 2/29
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(2)
    end

    it 'counts 28 days for client 5 (1e)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '5')
      # Note 2016 is a leap year
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(29)
    end

    it 'client 6 has no stays (1f)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '6')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }).to be_empty
    end
  end
end
