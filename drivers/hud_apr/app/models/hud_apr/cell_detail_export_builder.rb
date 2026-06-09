###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class CellDetailExportBuilder < ::HudReports::CellDetailExportBuilderBase
    def call
      scope = drilldown.base_scope
      presenter = presenter_class.new(scope, drilldown.report, @user, question: drilldown.measure, format: :xlsx)
      package = build_presenter_package(scope, presenter, drilldown.name)

      Result.new(
        name: drilldown.name,
        filename: "#{drilldown.name} Cell Detail.xlsx",
        data: package.to_stream.read,
      )
    end

    def generator_for_report
      concern_class = case report_type
      when 'apr' then HudApr::Apr::AprConcern
      when 'caper' then HudApr::Caper::CaperConcern
      when 'ce_apr' then HudApr::CeApr::CeAprConcern
      when 'dq' then HudApr::Dq::DqConcern
      else raise ArgumentError, "Unknown report type: #{report_type}"
      end

      options_version = @report.options&.dig('report_version').presence || 'fy2020'
      report_version = options_version.to_s.downcase.gsub(' ', '').to_sym

      generator_classes = concern_class.possible_generator_classes
      klass = generator_classes[report_version]

      klass ||= generator_classes[options_version.to_sym]
      klass ||= generator_classes[options_version.to_s]

      raise ArgumentError, "Unsupported version #{options_version} for #{report_type}" unless klass

      klass
    end

    private

    def presenter_class
      case report_type
      when 'ce_apr' then HudApr::CeAprDrilldownPresenter
      else HudApr::DrilldownPresenter
      end
    end

    def build_presenter_package(clients, presenter, name)
      headers = presenter.headers

      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: worksheet_name(name)) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          sheet.add_row(headers.values, style: title)

          clients.find_in_batches do |batch|
            preload_batch_policies(batch)

            batch.each do |record|
              row = headers.keys.map { |k| presenter.display_value(record, k) }
              sheet.add_row(row)
            end
          end
        end
      end
    end
  end
end
