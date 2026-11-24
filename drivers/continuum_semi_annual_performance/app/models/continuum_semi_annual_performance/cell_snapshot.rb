###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  # Copies the HUD cells a report needs into simple_report_cells, so the report
  # keeps its values if the HUD sub-report is later purged.
  class CellSnapshot
    SUMMARY_CELLS = { persons: ['Q7a', 'B6'], households: ['Q8a', 'B2'] }.freeze

    def initialize(report:, project_type:, hud_report:)
      @report = report
      @project_type = project_type.to_sym
      @hud_report = hud_report
    end

    def save!
      rows = RowDefinitions.rows(report.row_set, project_type)
      values = hud_values(rows)
      now = Time.current
      records = rows.map { |row| record("#{project_type}.#{row[:key]}", row_data(row, values), now) }
      records << record("#{project_type}.summary", summary_data(values), now)
      SimpleReports::ReportCell.insert_all(records)
    end

    private

    attr_reader :report, :project_type, :hud_report

    def tables(rows)
      (rows.flat_map { |row| row[:cells] || [] }.map { |cell| cell[:table] } + SUMMARY_CELLS.values.map(&:first)).uniq
    end

    # One read-only query; `answer` would create blank cells and query per row.
    def hud_values(rows)
      hud_report.report_cells.
        where(universe: false, question: tables(rows)).
        pluck(:question, :cell_name, :summary).
        to_h { |question, cell_name, summary| [[question, cell_name], summary] }
    end

    def value_for(values, table, cell)
      raw = values[[table, cell]]
      return 0 if raw.nil? || raw == 'NaN'

      raw.is_a?(String) ? raw.to_f : raw
    end

    def row_data(row, values)
      data = { label: row[:label], header: row[:header], level: row[:level], format: row[:format], source: row[:source], value: nil, parts: [] }
      return data if row[:header]

      data[:parts] = row[:cells].map { |cell| cell.merge(hud_report_id: hud_report.id).slice(:report, :hud_report_id, :table, :cell) }
      amounts = row[:cells].map { |cell| value_for(values, cell[:table], cell[:cell]) }
      data[:value] = row[:op] == :sum ? amounts.sum : amounts.first
      data
    end

    def summary_data(values)
      counts = SUMMARY_CELLS.transform_values { |(table, cell)| value_for(values, table, cell) }
      { projects: hud_report.project_ids.size, hud_report_id: hud_report.id }.merge(counts)
    end

    def record(name, data, now)
      { report_instance_id: report.id, name: name, universe: false, structured_data: data, created_at: now, updated_at: now }
    end
  end
end
