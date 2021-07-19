require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureThree, type: :model do
  let!(:all_hud_reports_user_role) { create :can_view_all_hud_reports }
  let!(:user) { create :user, roles: [all_hud_reports_user_role] }
  let!(:report) { create :spm_measure_three_fy2019 }
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

  let(:measure) { ReportGenerators::SystemPerformance::Fy2019::MeasureThree.new({}) }

  before(:all) do
    import_hmis_csv_fixture('spec/fixtures/files/system_performance/measure_three')
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

  it 'counts 3 clients' do
    expect(report_result.results['three2_c2']['value']).to eq(3)
  end

  it 'counts client 4 in ES' do
    expect(report_result.results['three2_c3']['value']).to eq(1)
    client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '4')
    expect(report_result.support['three2_c3']['support']['counts'].select { |c| c[0] == client.id }).to_not be_empty
  end

  it 'counts client 5 in SH' do
    expect(report_result.results['three2_c4']['value']).to eq(1)
    client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '5')
    expect(report_result.support['three2_c4']['support']['counts'].select { |c| c[0] == client.id }).to_not be_empty
  end

  it 'counts client 6 in TH' do
    expect(report_result.results['three2_c5']['value']).to eq(1)
    client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '6')
    expect(report_result.support['three2_c5']['support']['counts'].select { |c| c[0] == client.id }).to_not be_empty
  end
end
