###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Report
  class Exit < Base
    self.table_name = :report_exits

    belongs :enrollment
    belongs :client
    belongs :demographic
  end
end
