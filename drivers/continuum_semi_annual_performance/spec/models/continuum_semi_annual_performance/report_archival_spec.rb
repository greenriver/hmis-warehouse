###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContinuumSemiAnnualPerformance::Report, type: :model do
  let(:user) { create(:acl_user) }
  let(:report) { ContinuumSemiAnnualPerformance::MidYearReport.create!(user_id: user.id, options: { coc_codes: ['XX-500'] }) }

  [ContinuumSemiAnnualPerformance::MidYearReport, ContinuumSemiAnnualPerformance::EndOfYearReport].each do |klass|
    it "selects saved #{klass.name} rows the way the archive task does" do
      saved = klass.create!(user_id: user.id, options: { coc_codes: ['XX-500'] })

      selected = SimpleReports::ReportInstance.of_types(Rails.application.config.report_archival_types)

      expect(selected).to include(saved)
    end
  end

  it 'archives report cells to a CSV named for the report type and id' do
    config = report.archival_csv_config.fetch(:report_cells_csv)

    expect(config[:association]).to eq(:report_cells)
    expect(report.instance_exec(&config[:filename])).to eq("continuum_semi_annual_performance_mid_year_report-report_cells-#{report.id}.csv")
    expect(report.report_cells_csv).to be_an(ActiveStorage::Attached::Many)
  end

  it 'restores a purged snapshot cell from the archive' do
    data = { 'label' => 'Persons served', 'value' => 12.0 }
    report.report_cells.create!(name: 'es.r1', universe: false, structured_data: data)
    report.complete

    expect(Reports::ArchiveReportService.new(report).archive!).to be(true)
    report.reload
    expect(report.archived?).to be(true)

    report.hard_delete_archival_association(:report_cells)
    expect(report.report_cells.reload).to be_empty

    expect(Reports::ReloadReportFromCsvService.new(report).reload![:success]).to be(true)
    expect(report.report_cells.reload.map { |cell| [cell.name, cell.structured_data] }).to eq([['es.r1', data]])
  end
end
