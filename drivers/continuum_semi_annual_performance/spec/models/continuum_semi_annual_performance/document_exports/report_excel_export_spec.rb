###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe ContinuumSemiAnnualPerformance::DocumentExports::ReportExcelExport, type: :model do
  let(:report_class) { ContinuumSemiAnnualPerformance::EndOfYearReport }
  let(:report_definition_url) { 'continuum_semi_annual_performance/warehouse_reports/end_of_year_reports' }
  # The shared context defines `report_attributes` as {}, so each include re-declares it.
  it_behaves_like 'a document export limited to visible reports' do
    let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }
  end

  describe 'workbook' do
    include_context 'report visibility users'
    let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }

    before do
      hud = create(
        :hud_reports_report_instance,
        report_name: 'APR',
        user_id: own_reports_user.id,
        project_ids: [1],
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 12, 31),
      )
      hud.report_cells.create!(question: 'Q7a', cell_name: 'B6', universe: false, summary: 42)
      hud.report_cells.create!(question: 'Q8a', cell_name: 'B2', universe: false, summary: 30)
      ContinuumSemiAnnualPerformance::CellSnapshot.new(report: own_report, project_type: :es, hud_report: hud).save!
    end

    def sheets(tab)
      export = described_class.new(user: own_reports_user, query_string: { 'id' => own_report.id, 'tab' => tab }.to_query)
      export.perform
      file = Tempfile.new(['coc_semi_annual', '.xlsx'], binmode: true)
      file.write(export.file_data)
      file.close
      Roo::Excelx.new(file.path)
    end

    it 'writes the summary and every tab for the full CoC' do
      expect(sheets('all').sheets).to eq(['Summary', 'ES', 'Report Info'])
    end

    it 'writes the summary row with the type, project count, persons and households' do
      book = sheets('all')
      book.default_sheet = 'Summary'

      expect(book.row(1)).to eq(['Project type', 'Projects', 'Persons served', 'Households served'])
      expect(book.row(2)).to eq([ContinuumSemiAnnualPerformance::ReportsHelper.tab_title(:es), 1, 42, 30])
    end

    it 'refuses a purged report' do
      own_report.update!(archival_metadata: { 'purged_at' => Time.current.iso8601 })

      expect(described_class.new(user: own_reports_user, query_string: { 'id' => own_report.id }.to_query).authorized?).to be(false)
    end

    it 'refuses an unfinished report' do
      own_report.update!(completed_at: nil)

      expect(described_class.new(user: own_reports_user, query_string: { 'id' => own_report.id }.to_query).authorized?).to be(false)
    end

    it 'refuses a hash-valued id without raising' do
      export = described_class.new(user: own_reports_user, query_string: { 'id' => { 'a' => '1' } }.to_query)

      expect(export.authorized?).to be(false)
    end

    it 'refuses a tab the report does not have' do
      export = described_class.new(user: own_reports_user, query_string: { 'id' => own_report.id, 'tab' => 'rrh' }.to_query)

      expect(export.authorized?).to be(false)
    end

    it 'writes only the chosen tab, with the value from the HUD cell' do
      book = sheets('es')
      book.default_sheet = 'ES'
      row = (1..book.last_row).find { |i| book.cell(i, 1) == 'Persons Served - Total' }

      expect(book.sheets).to eq(['ES', 'Report Info'])
      expect(book.cell(row, 2)).to eq('APR Table Q7a - Cell B6')
      expect(book.cell(row, 3)).to eq(42)
    end
  end
end
