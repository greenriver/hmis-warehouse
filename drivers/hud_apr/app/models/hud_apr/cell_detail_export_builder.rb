###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  # Builds Excel exports for APR, CAPER, CeAPR, and DQ report cell details.
  class CellDetailExportBuilder < ::HudReports::CellDetailExportBuilderBase
    def initialize(user:, report:, question:, cell_id:, table:, report_type:)
      super(user: user, report: report, measure_id: question, cell_id: cell_id, table: table)
      @report_type = report_type
    end

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
  end
end
