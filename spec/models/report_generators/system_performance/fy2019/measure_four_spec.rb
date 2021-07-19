require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureFour, type: :model do
  let!(:all_hud_reports_user_role) { create :can_view_all_hud_reports }
  let!(:user) { create :user, roles: [all_hud_reports_user_role] }
  let!(:report) { create :spm_measure_four_fy2019 }
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

  let(:measure) { ReportGenerators::SystemPerformance::Fy2019::MeasureFour.new({}) }

  before(:all) do
    import_hmis_csv_fixture('spec/fixtures/files/system_performance/measure_four')
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

  it 'counts 2 stayers' do
    expect(report_result.results['four1_c2']['value']).to eq(2)
  end

  it 'counts 1 stayers with increase' do
    expect(report_result.results['four1_c3']['value']).to eq(1)
  end

  it 'counts 2 leavers' do
    expect(report_result.results['four4_c2']['value']).to eq(2)
  end

  it 'counts 1 leavers with increase' do
    expect(report_result.results['four4_c3']['value']).to eq(1)
  end
end
