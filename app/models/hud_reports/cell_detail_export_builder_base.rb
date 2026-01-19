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

    def initialize(user:, report:, measure_id:, cell_id:, table:)
      @user = user
      @report = report
      @measure_id = measure_id
      @cell_id = cell_id
      @table = table
    end

    def call
      generator_class = generator_for_report
      question_or_measure = generator_class.valid_question_number(@measure_id)
      cell = generator_class.valid_cell_name(@cell_id)
      name = build_name(generator_class, question_or_measure, cell)
      headers = generator_class.column_headings(question_or_measure)
      clients = scoped_clients(generator_class, question_or_measure, cell)
      package = build_package(clients, headers, name)

      Result.new(
        name: name,
        filename: "#{name} Cell Detail.xlsx",
        data: package.to_stream.read,
      )
    end

    def generator_for_report
      # Subclasses must implement - should return a generator class, not an instance
      raise NotImplementedError
    end

    private

    attr_reader :user

    def build_name(generator_class, question_or_measure, cell)
      generator_class.drilldown_name(
        question: question_or_measure,
        table: @table,
        cell: cell
      ).strip
    end

    def scoped_clients(generator_class, question_or_measure, cell)
      client_scope_for_question(generator_class, question_or_measure).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct
    end

    def client_scope_for_question(generator_class, question_or_measure)
      if generator_class.respond_to?(:client_scope)
        generator_class.client_scope(question_or_measure)
      else
        generator_class.client_class(question_or_measure)
      end
    end

    def build_package(clients, headers, name)
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: worksheet_name(name)) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          final_headers = normalized_headers(headers)
          sheet.add_row(final_headers.values, style: title)

          # Use find_in_batches to avoid loading all clients into memory and to preload policies incrementally
          clients.find_in_batches do |batch|
            preload_batch_policies(batch)

            batch.each do |client|
              pii_policy = user.reporting_policy_for_project(
                project_id: client.project_id,
                mode: :download,
              )

              row = final_headers.keys.map do |key|
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

    def normalized_headers(headers)
      final_headers = headers.transform_keys(&:to_s)
      return final_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      generator_class = generator_for_report
      final_headers.except(*generator_class.pii_columns)
    end

    def preload_batch_policies(batch)
      project_ids = batch.map(&:project_id).compact.uniq
      user.policy_context.preload_project_dependencies(project_ids) if project_ids.any?
    end
  end
end
