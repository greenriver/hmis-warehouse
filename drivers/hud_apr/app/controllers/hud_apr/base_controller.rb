###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class BaseController < ::HudReports::BaseController
    before_action :filter

    # This method allow picking the version of the report, we only need this during the transition
    TodoOrDie('Remove active_report_versions once we are on FY 2026', by: '2025-11-01')
    def active_report_versions
      return {} if default_report_version == :fy2026 && ! Rails.env.development?

      {
        fy2024: 'FY 2024',
        fy2026: 'FY 2026',

      }.invert.freeze
    end
    helper_method :active_report_versions
  end
end
