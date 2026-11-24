###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContinuumSemiAnnualPerformance::CellSnapshot, type: :model do
  let(:user) { create(:acl_user) }
  let(:report) { ContinuumSemiAnnualPerformance::EndOfYearReport.create!(user_id: user.id, options: { coc_codes: ['XX-500'] }) }
  let(:hud_report) do
    create(
      :hud_reports_report_instance,
      report_name: 'Test APR',
      user_id: user.id,
      project_ids: [11, 12],
      start_date: Date.new(2026, 1, 1),
      end_date: Date.new(2026, 12, 31),
    )
  end

  def answer(table, cell, summary)
    hud_report.report_cells.create!(question: table, cell_name: cell, universe: false, summary: summary)
  end

  before do
    answer('Q7a', 'B6', 42)
    answer('Q8a', 'B2', 30)
    answer('Q6a', 'F2', '0.0123')
    answer('Q22b', 'B2', 12.5)
    answer('Q25a', 'B2', 3)
    answer('Q25a', 'B3', 4)
    described_class.new(report: report, project_type: :rrh, hud_report: hud_report).save!
  end

  def row(label) = report.rows_for(:rrh).find { |r| r.label == label }

  it 'formats counts, percentages and averages from the HUD cells' do
    expect(row('Persons Served - Total').display_value).to eq('42')
    expect(row('Name Error Rate').display_value).to eq('1.23%')
    expect(row('Leavers Average Length').display_value).to eq('12.5')
  end

  it 'adds summed rows and links each part to its HUD cell' do
    total = row('Total Number of Veterans')

    expect(total.display_value).to eq('7')
    expect(total.parts).to contain_exactly(
      { 'report' => 'apr', 'hud_report_id' => hud_report.id, 'table' => 'Q25a', 'cell' => 'B2' },
      { 'report' => 'apr', 'hud_report_id' => hud_report.id, 'table' => 'Q25a', 'cell' => 'B3' },
    )
  end

  it 'shows 0 for a cell the generator never wrote' do
    expect(row('Stayers Median Length').display_value).to eq('0.0')
  end

  it 'keeps spec order and heading levels' do
    labels = report.rows_for(:rrh).first(3).map { |r| [r.label, r.header, r.level] }

    expect(labels).to eq([['Q6a: Personally Identifiable Information', true, 1], ['Name Total', false, nil], ['Name Error Rate', false, nil]])
  end

  it 'records the summary counts for the project type' do
    expect(report.summary_rows).to eq([{ project_type: :rrh, projects: 2, persons: 42, households: 30 }])
    expect(report.hud_report_ids).to eq(rrh: hud_report.id)
  end

  it 'leaves the HUD report cells as it found them' do
    expect(hud_report.report_cells.count).to eq(6)
  end

  context 'when the generator wrote NaN' do
    let(:nan_report) { ContinuumSemiAnnualPerformance::EndOfYearReport.create!(user_id: user.id, options: { coc_codes: ['XX-500'] }) }

    it 'shows 0' do
      answer('Q22b', 'C2', 'NaN')
      described_class.new(report: nan_report, project_type: :rrh, hud_report: hud_report).save!

      expect(nan_report.rows_for(:rrh).find { |r| r.label == 'Stayers Average Length' }.display_value).to eq('0.0')
    end
  end
end
