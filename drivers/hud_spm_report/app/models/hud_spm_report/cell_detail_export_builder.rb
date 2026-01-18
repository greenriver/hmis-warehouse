###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  class CellDetailExportBuilder < ::HudReports::CellDetailExportBuilderBase
    def initialize(user:, report:, measure_id:, cell_id:, table:, generator_class: nil)
      super(user: user, report: report, measure_id: measure_id, cell_id: cell_id, table: table)
      @generator_class = generator_class
    end

    private

    def generator_for_report
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
  end
end
