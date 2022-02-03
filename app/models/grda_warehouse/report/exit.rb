###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Report
  class Exit < Base
    self.table_name = :report_exits

    belongs :enrollment
    belongs :client
    belongs :demographic
  end
end
