###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class BaseController < ::HudReports::BaseController
    before_action :filter

    def active_report_versions
      {
        fy2026: 'FY 2026',

      }.invert.freeze
    end
    helper_method :active_report_versions
  end
end
