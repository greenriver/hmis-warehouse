###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe ContinuumSemiAnnualPerformance::EndOfYearReport, type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:es_project) { create_project(project_type: 0, coc_code: 'XX-500') }
  let(:rrh_project) { create_project(project_type: 13, coc_code: 'XX-500') }
  let(:other_coc_project) { create_project(project_type: 0, coc_code: 'XX-501') }
  let(:collection) { create(:collection) }
  let(:user) do
    create(:acl_user).tap do |u|
      setup_access_control(u, create(:role, can_view_assigned_reports: true, can_view_projects: true), collection)
    end
  end
  let(:visible_projects) { [es_project, rrh_project, other_coc_project] }

  before do
    # Filter#update drops a CoC code without an active lookup row; check the factory's attribute names.
    ['XX-500', 'XX-501'].each { |code| create(:lookup_coc, coc_code: code) }
    collection.set_viewables({ projects: visible_projects.map(&:id) })
    [es_project, es_project, rrh_project, other_coc_project].each do |project|
      client = create_client_with_warehouse_link
      create_enrollment(client: client, project: project, entry_date: Date.new(2026, 2, 1))
    end
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  let(:all_type_codes) { HudHelper.util.performance_reporting.keys.map(&:to_s) }

  def run(project_type_codes: all_type_codes, project_ids: [])
    report = described_class.new(user_id: user.id)
    report.filter = ContinuumSemiAnnualPerformance::Filter.new(
      user_id: user.id, start: Date.new(2026, 1, 1), end: Date.new(2026, 12, 31),
      coc_codes: ['XX-500'], project_type_codes: project_type_codes, project_ids: project_ids, enforce_one_year_range: false
    )
    report.save!
    report.run_and_save!
    report
  end

  def hud_report(report, type) = HudReports::ReportInstance.find(report.hud_report_ids.fetch(type))

  it 'runs one sub-report per project type that has projects in the CoC' do
    report = run

    expect(report.tabs).to eq([:summary, :es, :rrh, :ce_tab])
    expect(hud_report(report, :es).project_ids).to contain_exactly(es_project.id)
    expect(hud_report(report, :es).user_id).to eq(user.id)
  end

  it 'deletes its previous cells when run again instead of orphaning them' do
    report = run
    cell_count = SimpleReports::ReportCell.with_deleted.where(report_instance_id: report.id).count
    orphans_before = SimpleReports::ReportCell.with_deleted.where(report_instance_id: nil).count

    report.run_and_save!

    expect(SimpleReports::ReportCell.with_deleted.where(report_instance_id: report.id).count).to eq(cell_count)
    expect(SimpleReports::ReportCell.with_deleted.where(report_instance_id: nil).count).to eq(orphans_before)
  end

  it 'gives each sub-report the report dates' do
    report = run

    [:es, :ce_tab].each do |type|
      expect(hud_report(report, type).start_date).to eq(Date.new(2026, 1, 1))
      expect(hud_report(report, type).end_date).to eq(Date.new(2026, 12, 31))
    end
  end

  it 'reports the persons served the ES APR counted' do
    report = run
    es = report.summary_rows.find { |r| r[:project_type] == :es }

    expect(es[:persons]).to eq(2)
    expect(es[:persons]).to eq(hud_report(report, :es).answer(question: 'Q7a', cell: 'B6').summary)
  end

  it 'stores percent and average rows exactly as the ES APR computed them' do
    report = run
    es_hud = hud_report(report, :es)
    value = ->(label) { report.rows_for(:es).find { |r| r.label == label }.value }

    expect(value.call('Name Error Rate')).to eq(es_hud.answer(question: 'Q6a', cell: 'F2').summary.to_f)
    expect(value.call('Stayers Average Length')).to eq(es_hud.answer(question: 'Q22b', cell: 'C2').summary.to_f)
    expect(value.call('Stayers Average Length')).to be > 0
  end

  it 'runs the CE APR on every selected project in the CoC' do
    expect(hud_report(run, :ce_tab).project_ids).to contain_exactly(es_project.id, rrh_project.id)
  end

  it 'limits the tabs and the CE APR to the project types the user kept' do
    report = run(project_type_codes: ['rrh'])

    expect(report.tabs).to eq([:summary, :rrh, :ce_tab])
    expect(hud_report(report, :ce_tab).project_ids).to contain_exactly(rrh_project.id)
  end

  it 'keeps a picked project out of another project type\'s APR' do
    report = run(project_type_codes: ['es'], project_ids: [rrh_project.id])

    expect(hud_report(report, :es).project_ids).to contain_exactly(es_project.id)
    expect(hud_report(report, :rrh).project_ids).to contain_exactly(rrh_project.id)
    expect(report.summary_rows.find { |r| r[:project_type] == :es }[:persons]).to eq(2)
  end

  it 'runs only the picked project when no project type is selected' do
    report = run(project_type_codes: [], project_ids: [rrh_project.id])

    expect(report.tabs).to eq([:summary, :rrh, :ce_tab])
    expect(hud_report(report, :ce_tab).project_ids).to contain_exactly(rrh_project.id)
  end

  context 'when the user cannot see the RRH project' do
    let(:visible_projects) { [es_project] }

    it 'leaves RRH out of the report and its sub-reports' do
      report = run

      expect(report.tabs).to eq([:summary, :es, :ce_tab])
      expect(hud_report(report, :ce_tab).project_ids).to contain_exactly(es_project.id)
    end
  end

  it 'fails without running a sub-report when the CoC is no longer available' do
    report = described_class.new(user_id: user.id)
    report.filter = ContinuumSemiAnnualPerformance::Filter.new(user_id: user.id, start: Date.new(2026, 1, 1), end: Date.new(2026, 12, 31), coc_codes: ['XX-500'], project_type_codes: all_type_codes, enforce_one_year_range: false)
    report.save!
    GrdaWarehouse::Lookups::CocCode.where(coc_code: 'XX-500').find_each { |coc| coc.update!(active: false) }
    queued = described_class.find(report.id)

    expect { queued.run_and_save! }.to raise_error(ContinuumSemiAnnualPerformance::SubReportRunner::CocUnavailable)
    expect(HudReports::ReportInstance.where(user_id: user.id)).not_to exist
    expect(queued.reload.failed_at).to be_present
  end

  it 'leaves CE out of the Mid-Year report' do
    report = ContinuumSemiAnnualPerformance::MidYearReport.new(user_id: user.id)
    report.filter = ContinuumSemiAnnualPerformance::Filter.new(user_id: user.id, start: Date.new(2026, 1, 1), end: Date.new(2026, 6, 30), coc_codes: ['XX-500'], project_type_codes: all_type_codes, enforce_one_year_range: false)
    report.save!
    report.run_and_save!

    expect(report.tabs).to eq([:summary, :es, :rrh])
    expect(hud_report(report, :es).end_date).to eq(Date.new(2026, 6, 30))
  end
end
