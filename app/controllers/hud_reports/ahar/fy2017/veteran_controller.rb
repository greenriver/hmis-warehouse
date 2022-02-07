###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports::Ahar::Fy2017
  class VeteranController < BaseController
    def report_source
      Reports::Ahar::Fy2017::Veteran
    end
  end
end
