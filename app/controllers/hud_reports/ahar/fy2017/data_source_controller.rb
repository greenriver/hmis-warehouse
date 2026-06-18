###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports::Ahar::Fy2017
  class DataSourceController < BaseController
    def report_source
      Reports::Ahar::Fy2017::ByDataSource
    end
  end
end
