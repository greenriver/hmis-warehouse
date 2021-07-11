require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::MeasureTwo, type: :model do
  let!(:all_hud_reports_user_role) { create :can_view_all_hud_reports }
  let!(:user) { create :user, roles: [all_hud_reports_user_role] }
  let!(:report) { create :spm_measure_two_fy2019 }
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

  let(:measure) { ReportGenerators::SystemPerformance::Fy2019::MeasureTwo.new({}) }

  before(:all) do
    import_hmis_csv_fixture('spec/fixtures/files/system_performance/measure_two')
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

  it 'counts 3 clients exiting to PH' do
    expect(report_result.results['two_b7']['value']).to eq(3)
  end

  it 'counts 0 clients returning to homelessness from PH' do
    expect(report_result.results['two_g6']['value']).to eq(0)
  end

  it 'counts 0 clients returning to homelessness from TH' do
    expect(report_result.results['two_g4']['value']).to eq(0)
  end

  it 'counts 2 clients returning to homelessness from ES' do
    expect(report_result.results['two_g3']['value']).to eq(2)
  end

  it 'counts 0 clients returning to homelessness from ES betwen 6 months and a year' do
    expect(report_result.results['two_c3']['value']).to eq(0)
  end

  it 'counts 2 clients returning to homelessness' do
    expect(report_result.results['two_i7']['value']).to eq(2)
  end

  it 'counts no clients returning to homelessness in less than 6 months' do
    expect(report_result.results['two_c7']['value']).to eq(0)
  end

  it 'counts no clients returning to homelessness in 6-12 months' do
    expect(report_result.results['two_e7']['value']).to eq(0)
  end

  it 'count 2 clients returning to homelessness in 13-24 months' do
    expect(report_result.results['two_g7']['value']).to eq(2)
  end
end
