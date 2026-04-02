###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  class CellDetailExportBuilder < ::HudReports::CellDetailExportBuilderBase
    def initialize(generator_class: nil, **kwargs)
      super(**kwargs)
      @generator_class = generator_class
    end

    def generator_for_report
      klass = @generator_class || possible_generator_classes[report_version]
      raise ArgumentError, "Unsupported SPM generator version: #{report_version}" unless klass

      klass
    end

    private

    def report_version
      (@report.options&.dig('report_version').presence || 'fy2026').to_sym
    end

    def possible_generator_classes
      HudSpmReport::BaseController.new.possible_generator_classes
    end
  end
end
