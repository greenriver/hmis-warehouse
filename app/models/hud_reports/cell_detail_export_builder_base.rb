###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'axlsx'
module HudReports
  # Base class for building Excel exports of HUD report cell details.
  #
  # Subclasses must implement:
  # - generator_for_report: returns a generator class (not an instance)
  #
  # Subclasses can optionally override:
  # - scoped_clients: returns an ActiveRecord relation of clients for the cell
  # - normalized_headers: modifies headers before export (e.g., for PII filtering)
  #
  # The generator class must respond to:
  # - valid_question_number(measure_id)
  # - file_prefix
  # - column_headings(question_or_measure)
  # - pii_columns (optional, for filtering PII)
  class CellDetailExportBuilderBase
    Result = Struct.new(:name, :filename, :data, keyword_init: true)

    def initialize(user:, report: nil, measure_id: nil, cell_id: nil, table: nil, drilldown: nil, report_type: nil, **_kwargs)
      @user = user
      @drilldown = drilldown
      @report = report || drilldown&.report
      @measure_id = measure_id || drilldown&.measure
      @cell_id = cell_id || drilldown&.cell
      @table = table || drilldown&.table
      @report_type = report_type || drilldown&.report_type
    end

    def call
      package = build_package(drilldown.base_scope, drilldown.export_headers, drilldown.name)

      Result.new(
        name: drilldown.name,
        filename: "#{drilldown.name} Cell Detail.xlsx",
        data: package.to_stream.read,
      )
    end

    def generator_for_report
      # Subclasses must implement - should return a generator class, not an instance
      raise NotImplementedError
    end

    def drilldown
      @drilldown ||= generator_for_report.drilldown_context(
        report: @report,
        measure_id: @measure_id,
        cell_id: @cell_id,
        table_id: @table,
        report_type: @report_type,
      )
    end

    private

    attr_reader :user, :report_type

    def build_package(clients, headers, name)
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: worksheet_name(name)) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          sheet.add_row(headers.values, style: title)

          # Use find_in_batches to avoid loading all clients into memory and to preload policies incrementally
          clients.find_in_batches do |batch|
            preload_batch_policies(batch)

            batch.each do |client|
              pii_policy = user.reporting_policy_for_project(
                project_id: client.project_id,
                mode: :download,
              )

              row = headers.keys.map do |key|
                client.display_value(key, pii_policy: pii_policy, include_content_tag: false)
              end
              sheet.add_row(row)
            end
          end
        end
      end
    end

    def worksheet_name(name)
      "#{name} Detail".slice(0, 30).gsub(/[:\/\?*\[\]\\]/, ' ')
    end

    def preload_batch_policies(batch)
      project_ids = batch.map(&:project_id).compact.uniq
      user.policy_context.preload_project_dependencies(project_ids) if project_ids.any?
    end
  end
end
