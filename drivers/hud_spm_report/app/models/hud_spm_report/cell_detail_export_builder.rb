# frozen_string_literal: true

module HudSpmReport
  class CellDetailExportBuilder
    require 'axlsx'

    Result = Struct.new(:name, :filename, :data, keyword_init: true)

    def initialize(user:, report:, measure_id:, cell_id:, table:, generator_class: nil)
      @user = user
      @report = report
      @measure_id = measure_id
      @cell_id = cell_id
      @table = table
      @generator_class = generator_class
    end

    def call
      generator = generator_class_for_report
      question = generator.valid_question_number(@measure_id)
      cell = @report.valid_cell_name(@cell_id)
      name = "#{generator.file_prefix} #{question} #{cell}".strip
      headers = generator.column_headings(question)
      clients = scoped_clients(generator, question, cell)
      package = build_package(clients, headers, generator, name)

      Result.new(
        name: name,
        filename: "#{name} Cell Detail.xlsx",
        data: package.to_stream.read,
      )
    end

    private

    attr_reader :user

    def generator_class_for_report
      klass = @generator_class || possible_generator_classes[report_version]
      raise ArgumentError, "Unsupported SPM generator version: #{report_version}" unless klass

      klass
    end

    def report_version
      (@report.options&.dig('report_version').presence || 'fy2024').to_sym
    end

    def possible_generator_classes
      HudSpmReport::BaseController.new.possible_generator_classes
    end

    def scoped_clients(generator, question, cell)
      generator.client_scope(question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct
    end

    def build_package(clients, headers, generator, name)
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: worksheet_name(name)) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          final_headers = normalized_headers(headers, generator)
          sheet.add_row(final_headers.values, style: title)
          preload_policies(clients)
          clients.find_each do |client|
            pii_policy = user.reporting_policy_for_project(project_id: client.project_id, mode: :download)
            row = final_headers.keys.map do |key|
              client.display_value(key, pii_policy: pii_policy, include_content_tag: false)
            end
            sheet.add_row(row)
          end
        end
      end
    end

    def worksheet_name(name)
      "#{name} Detail".slice(0, 30).gsub(/[:\\ \/ ? * \[ \]]/, ' ')
    end

    def normalized_headers(headers, generator)
      final_headers = headers.transform_keys(&:to_s)
      return final_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      final_headers.except(*generator.pii_columns)
    end

    def preload_policies(clients)
      return unless clients.respond_to?(:pluck_project_ids)

      user.policy_context.preload_project_dependencies(clients.pluck_project_ids)
    end
  end
end
