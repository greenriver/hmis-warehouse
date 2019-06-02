###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports::Ahar::Fy2017
  class DataSourceController < BaseController
   
    def report_source
      Reports::Ahar::Fy2017::ByDataSource
    end

  end
end