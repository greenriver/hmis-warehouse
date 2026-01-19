###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # Encapsulates the state and logic for a HUD report cell drill-down.
  # This avoids polluting controllers with numerous instance variables and
  # centralizes the logic for scope building, search, and count calculation.
  DrilldownContext = Struct.new(
    :report,
    :generator,
    :measure,
    :cell,
    :table,
    :search_term,
    :searchable,
    :filtered_count,
    :total_count,
    :name,
    :headers,
    :report_type,
    keyword_init: true,
  ) do
    # Factory method to build a context from raw components.
    # It handles validation and sanitization internally.
    def self.build(report:, generator:, measure_id:, cell_id:, table_id:, report_type: nil)
      new(
        report: report,
        generator: generator,
        measure: valid_measure(measure_id, generator: generator),
        cell: valid_cell_name(cell_id),
        table: valid_table_name(table_id, generator: generator),
        report_type: report_type,
      )
    end

    # Sanitizes a cell name (usually alphanumeric)
    def self.valid_cell_name(cell_name)
      cell_name&.match(/[.A-Z0-9]+/i).to_s
    end

    def self.valid_measure(measure_id, generator:)
      if generator.respond_to?(:valid_question_number) && generator.method(:valid_question_number).owner != HudReports::GeneratorBase
        generator.valid_question_number(measure_id)
      elsif generator.respond_to?(:questions)
        generator.questions.keys.detect { |q| q == measure_id } || generator.questions.keys.first
      else
        measure_id.to_s
      end
    end

    # Sanitizes a table name (alphanumeric and dashes)
    def self.valid_table_name(table_name, generator: nil)
      table_name&.match(/[.A-Z0-9-]+/i).to_s
    end

    def name
      return self[:name] if self[:name]

      parts = ["#{generator.file_prefix}: #{measure}"]
      parts << "Table #{table}" if table.present?
      parts << "Cell #{cell}" if cell.present?
      self[:name] = parts.join(' / ')
    end

    def breadcrumb_label
      "« #{generator.file_prefix} #{measure} Results"
    end

    def headers
      self[:headers] ||= generator.column_headings(measure)
    end

    def query_params
      {
        question: measure, # Standardized key for most reports
        measure_id: measure, # Legacy/SPM support
        cell_id: cell,
        id: cell,
        table: table,
        report_type: report_type,
      }.compact
    end

    def filtered?
      searchable? && search_term.present?
    end

    def base_scope
      client_scope_for_measure.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(table).for_cell(cell)).
        merge(::HudReports::ReportInstance.where(id: report.id)).
        distinct
    end

    def client_scope_for_measure
      return generator.client_scope(measure) if generator.respond_to?(:client_scope)

      generator.client_class(measure)
    end

    def pii_columns
      generator.respond_to?(:pii_columns) ? generator.pii_columns : []
    end

    def export_headers
      h = headers.transform_keys(&:to_s)
      return h if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      h.except(*pii_columns)
    end

    def filtered_scope
      return base_scope unless searchable? && search_term.present?

      model = base_scope.model
      if model.respond_to?(:search_clients)
        model.search_clients(base_scope, search_term)
      else
        base_scope
      end
    end

    def set_counts!(scope, filtered: false)
      self.filtered_count = scope.count
      self.total_count = filtered ? base_scope.count : filtered_count
    end

    def searchable?
      return self[:searchable] unless self[:searchable].nil?

      self[:searchable] = !!(base_scope.model.respond_to?(:searchable?) && base_scope.model.searchable?)
    end

    def apply_search_query!(search_query)
      self.search_term = search_query&.query_params&.[](:q)&.to_s
    end
  end
end
