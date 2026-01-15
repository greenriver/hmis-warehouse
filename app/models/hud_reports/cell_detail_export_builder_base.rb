###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  class CellDetailExportBuilderBase
    require 'axlsx'

    Result = Struct.new(:name, :filename, :data, keyword_init: true)

    def initialize(user:, report:, measure_id:, cell_id:, table:)
      @user = user
      @report = report
      @measure_id = measure_id
      @cell_id = cell_id
      @table = table
    end

    def call
      generator = generator_for_report
      question_or_measure = generator.valid_question_number(@measure_id)
      cell = @report.valid_cell_name(@cell_id)
      name = build_name(generator, question_or_measure, cell)
      headers = generator.column_headings(question_or_measure)
      clients = scoped_clients(generator, question_or_measure, cell)
      package = build_package(clients, headers, name)

      Result.new(
        name: name,
        filename: "#{name} Cell Detail.xlsx",
        data: package.to_stream.read,
      )
    end

    private

    attr_reader :user

    def generator_for_report
      # Subclasses must implement - should return a generator class, not an instance
      raise NotImplementedError
    end

    def build_name(generator, question_or_measure, cell)
      "#{generator.file_prefix} #{question_or_measure} #{cell}".strip
    end

    def scoped_clients(generator, question_or_measure, cell)
      # Subclasses must implement - returns AR relation
      raise NotImplementedError
    end

    def build_package(clients, headers, name)
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: worksheet_name(name)) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          final_headers = normalized_headers(headers)
          sheet.add_row(final_headers.values, style: title)

          # Preload project dependencies before loading clients
          preload_policies(clients)

          # Use find_each to avoid loading all clients into memory
          clients.find_each do |client|
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

    def worksheet_name(name)
      "#{name} Detail".slice(0, 30).gsub(/[:\/\?*\[\]\\]/, ' ')
    end

    def normalized_headers(headers)
      # Subclasses can override for custom PII handling
      headers.transform_keys(&:to_s)
    end

    def preload_policies(clients)
      return unless clients.respond_to?(:pluck_project_ids) || clients.model.respond_to?(:pluck_project_ids)

      project_ids = clients.pluck_project_ids.compact
      user.policy_context.preload_project_dependencies(project_ids) if project_ids.any?
    end
  end
end
