###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# CellSnapshot records a cell the HUD report didn't write as 0, so a wrong address in rows.yml
# shows a plausible zero instead of failing. The APR writes every cell of each table it builds,
# even with no data, so an empty run lists every valid address.
RSpec.describe 'continuum_semi_annual_performance config/rows.yml cell addresses', type: :model do
  let(:user) { create(:acl_user) }

  def run_generator(report_key, row_types)
    generator = HudApr.current_generator(report: report_key)
    questions = row_types.flat_map { |row_set, project_type| ContinuumSemiAnnualPerformance::RowDefinitions.questions(row_set, project_type) }.uniq
    filter = ::Filters::HudFilterBase.new(user_id: user.id, enforce_one_year_range: false, start: Date.new(2026, 1, 1), end: Date.new(2026, 12, 31))
    hud_report = HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: questions)
    generator.new(hud_report).run!(email: false, manual: false)
    hud_report
  end

  def missing_cells(hud_report, row_types)
    rows = row_types.flat_map { |row_set, project_type| ContinuumSemiAnnualPerformance::RowDefinitions.rows(row_set, project_type) }
    expected = rows.flat_map { |row| row[:cells] || [] }.map { |cell| [cell[:table], cell[:cell]] }
    expected += ContinuumSemiAnnualPerformance::CellSnapshot::SUMMARY_CELLS.values
    expected.uniq - hud_report.report_cells.where(universe: false).pluck(:question, :cell_name)
  end

  it 'points every APR row at a cell the current APR writes' do
    row_types = [:mid_year, :end_of_year].product([:es, :hp, :so, :rrh])

    expect(missing_cells(run_generator(:apr, row_types), row_types)).to eq([])
  end

  it 'points every CE row at a cell the current CE APR writes' do
    row_types = [[:end_of_year, :ce_tab]]

    expect(missing_cells(run_generator(:ce_apr, row_types), row_types)).to eq([])
  end
end
