###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Report
  class Service < Base
    self.table_name = :report_services

    belongs :demographic   # source client
    belongs :client
  end
end