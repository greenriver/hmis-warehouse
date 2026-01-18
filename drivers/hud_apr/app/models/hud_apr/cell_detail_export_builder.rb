###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class CellDetailExportBuilder < ::HudReports::CellDetailExportBuilderBase
    def initialize(user:, report:, question:, cell_id:, table:, report_type:)
      super(user: user, report: report, measure_id: question, cell_id: cell_id, table: table)
      @report_type = report_type
    end

    private

    def generator_for_report
      concern_class = case @report_type
      when 'apr' then HudApr::Apr::AprConcern
      when 'caper' then HudApr::Caper::CaperConcern
      when 'ce_apr' then HudApr::CeApr::CeAprConcern
      when 'dq' then HudApr::Dq::DqConcern
      else raise ArgumentError, "Unknown report type: #{@report_type}"
      end

      options_version = @report.options&.dig('report_version').presence || 'fy2020'
      report_version = options_version.to_s.downcase.gsub(' ', '').to_sym

      generator_classes = concern_class.possible_generator_classes
      klass = generator_classes[report_version]

      # Fallback to direct lookup if slug doesn't match
      klass ||= generator_classes[options_version.to_sym]
      klass ||= generator_classes[options_version.to_s]

      raise ArgumentError, "Unsupported version #{options_version} for #{@report_type}" unless klass

      klass
    end

    def scoped_clients(generator_class, question, _cell)
      generator_class.client_class(question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell_id)).
        merge(::HudReports::ReportInstance.where(id: @report.id)).
        distinct
    end

    def normalized_headers(headers)
      generator_class = generator_for_report
      final_headers = generator_class.client_class(@measure_id).detail_headers.transform_keys(&:to_s)
      return final_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      final_headers.except(*generator_class.pii_columns)
    end
  end
end
