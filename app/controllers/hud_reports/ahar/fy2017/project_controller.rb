###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports::Ahar::Fy2017
  class ProjectController < BaseController
    def report_source
      Reports::Ahar::Fy2017::ByProject
    end
  end
end
