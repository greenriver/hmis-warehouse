###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Report
  class Exit < Base
    self.table_name = :report_exits

    belongs :enrollment
    belongs :client
    belongs :demographic
  end
end