###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
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

    def scoped_clients(_generator, _question, _cell)
      HudApr::Fy2020::AprClient.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell_id)).
        merge(::HudReports::ReportInstance.where(id: @report.id))
    end

    def normalized_headers(_headers)
      headers = HudApr::Fy2020::AprClient.detail_headers.transform_keys(&:to_s)
      return headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      headers.except('first_name', 'last_name', 'dob', 'ssn')
    end
  end
end
