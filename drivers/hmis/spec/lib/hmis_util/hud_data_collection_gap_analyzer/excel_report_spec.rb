###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::HudDataCollectionGapAnalyzer::ExcelReport do
  subject(:report) { described_class.new(result: result) }

  let(:result) do
    HmisUtil::HudDataCollectionGapAnalyzer::Result.new(
      summary_rows: summary_rows,
      field_gap_rows: field_gap_rows,
      form_gap_rows: form_gap_rows,
    )
  end
  let(:summary_rows) { [] }
  let(:field_gap_rows) { [] }
  let(:form_gap_rows) { [] }

  let(:workbook) { report.package.workbook }

  def rows_of(sheet_name)
    sheet = workbook.worksheets.find { |worksheet| worksheet.name == sheet_name }
    sheet.rows.map { |row| row.cells.map(&:value) }
  end

  # Only the keys the sheets address by name; identity values vary per example so that
  # sorting and grouping have something to discriminate on.
  def identity(project_id:, project_name: 'Bridge House', project_type_name: 'ES - Entry/Exit', funders: 'HUD: CoC')
    {
      project_id: project_id,
      project_name: project_name,
      project_type: 2,
      project_type_name: project_type_name,
      funders: funders,
      funder_components: 'HUD: CoC',
    }
  end

  def field_gap(link_id: 'q_4_02', record_type: 'INCOME_BENEFIT', **identity_attrs)
    identity(**identity_attrs).merge(
      role: :INTAKE,
      link_id: link_id,
      record_type: record_type,
      field_name: 'earnedAmount',
      count: 3,
      earliest: Date.new(2025, 1, 1),
      latest: Date.new(2025, 6, 1),
    )
  end

  def form_gap(form:, record_type:, **identity_attrs)
    identity(**identity_attrs).merge(
      form: form,
      record_type: record_type,
      count: 7,
      earliest: Date.new(2025, 2, 1),
      latest: Date.new(2025, 8, 1),
    )
  end

  it 'writes a summary sheet, both gap sheets, and the rollup' do
    expect(workbook.worksheets.map(&:name)).to contain_exactly(
      'Summary',
      'Field-Level Gaps',
      'Form-Level Gaps',
      'Patch Targeting Rollup',
    )
  end

  describe 'row rendering' do
    # Keys deliberately out of header order: a row is a plain hash, and the analyzer builds
    # field gap rows by merging onto the identity hash, so hash order is not header order.
    let(:field_gap_rows) do
      [
        {
          count: 3,
          field_name: 'earnedAmount',
          project_name: 'Bridge House',
          link_id: 'q_4_02',
          project_id: 41,
          role: :INTAKE,
          record_type: 'INCOME_BENEFIT',
          project_type: 2,
          project_type_name: 'ES - Entry/Exit',
          funders: 'HUD: CoC',
          funder_components: 'HUD: CoC',
          earliest: Date.new(2025, 1, 1),
          latest: Date.new(2025, 6, 1),
        },
      ]
    end

    it 'places each value under its own header rather than in the row hash\'s key order' do
      header, row = rows_of('Field-Level Gaps')

      expect(header.zip(row).to_h).to eq(
        'Project ID' => 41,
        'Project Name' => 'Bridge House',
        'Project Type' => 2,
        'Project Type Name' => 'ES - Entry/Exit',
        'Funders' => 'HUD: CoC',
        'Funder Components' => 'HUD: CoC',
        'Assessment' => 'INTAKE',
        'Link ID' => 'q_4_02',
        'Record Type' => 'INCOME_BENEFIT',
        'Field' => 'earnedAmount',
        'Records With Data' => 3,
        'Earliest Date' => Date.new(2025, 1, 1),
        'Latest Date' => Date.new(2025, 6, 1),
      )
    end
  end

  describe 'the summary sheet' do
    let(:summary_rows) do
      [identity(project_id: 41).merge(services_count: 12, services_earliest: Date.new(2025, 3, 1), services_latest: nil)]
    end

    it 'names a presence column after the key the analyzer put on the row' do
      expect(rows_of('Summary').first).to eq(
        [
          'Project ID', 'Project Name', 'Project Type', 'Project Type Name', 'Funders', 'Funder Components',
          'Services Count', 'Services Earliest', 'Services Latest'
        ],
      )
    end

    it 'writes one row per scanned project' do
      expect(rows_of('Summary').last).to eq(
        [41, 'Bridge House', 2, 'ES - Entry/Exit', 'HUD: CoC', 'HUD: CoC', 12, Date.new(2025, 3, 1), nil],
      )
    end

    context 'when no project was scanned' do
      let(:summary_rows) { [] }

      it 'writes the identity headers and no data rows' do
        expect(rows_of('Summary')).to eq(
          [['Project ID', 'Project Name', 'Project Type', 'Project Type Name', 'Funders', 'Funder Components']],
        )
      end
    end
  end

  describe 'the rollup sheet' do
    let(:field_gap_rows) { [field_gap(project_id: 41, link_id: 'q_4_02', record_type: 'INCOME_BENEFIT')] }
    let(:form_gap_rows) do
      [
        form_gap(project_id: 42, form: 'Service', record_type: 141),
        form_gap(project_id: 43, form: 'Current Living Situation', record_type: nil),
      ]
    end

    def rollup_column(header_name)
      header, *rows = rows_of('Patch Targeting Rollup')
      index = header.index(header_name)
      rows.map { |row| row[index] }
    end

    it 'carries every field gap and every form gap onto one sheet' do
      expect(rollup_column('Project ID')).to match_array([41, 42, 43])
    end

    it 'labels a field gap with its record type and link id' do
      expect(rollup_column('Element')).to include('INCOME_BENEFIT / q_4_02')
    end

    it 'labels a service form gap with the form name and its record type' do
      expect(rollup_column('Element')).to include('Service / 141')
    end

    it 'labels a form gap that names no record type with the form name alone' do
      expect(rollup_column('Element')).to include('Current Living Situation')
    end

    context 'with gaps that differ on each sort key' do
      let(:form_gap_rows) { [] }
      let(:field_gap_rows) do
        [
          field_gap(project_id: 1, funders: 'HUD: ESG', project_type_name: 'ES - Entry/Exit', record_type: 'INCOME_BENEFIT', project_name: 'Zeta'),
          field_gap(project_id: 2, funders: 'HUD: CoC', project_type_name: 'ES - Entry/Exit', record_type: 'INCOME_BENEFIT', project_name: 'Alpha'),
          field_gap(project_id: 3, funders: 'HUD: ESG', project_type_name: 'Street Outreach', record_type: 'HEALTH_AND_DV', project_name: 'Alpha'),
          field_gap(project_id: 4, funders: 'HUD: ESG', project_type_name: 'ES - Entry/Exit', record_type: 'INCOME_BENEFIT', project_name: 'Alpha'),
          field_gap(project_id: 5, funders: 'HUD: CoC', project_type_name: 'Street Outreach', record_type: 'INCOME_BENEFIT', project_name: 'Alpha'),
        ]
      end

      it 'orders rows by funders, then project type, then element, then project name' do
        expect(rollup_column('Project ID')).to eq([2, 5, 4, 1, 3])
      end
    end
  end
end
