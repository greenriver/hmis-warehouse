###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports::Ahar::Fy2017
  class ProjectController < BaseController
    def report_source
      Reports::Ahar::Fy2017::ByProject
    end
  end
end
