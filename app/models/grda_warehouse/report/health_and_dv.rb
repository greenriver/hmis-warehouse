###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Report
  class HealthAndDv < Base
    self.table_name = :report_health_and_dvs

    belongs :enrollment
    belongs :demographic   # source client
    belongs :client
    has_one :exit, through: :enrollment
  end
end