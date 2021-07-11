require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureFive, type: :model do
  let!(:all_hud_reports_user_role) { create :can_view_all_hud_reports }
  let!(:user) { create :user, roles: [all_hud_reports_user_role] }
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
    import_hmis_csv_fixture(
      'spec/fixtures/files/system_performance/measure_five',
      run_jobs: true,
    )
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
end
