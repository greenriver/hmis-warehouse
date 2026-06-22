###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Report
  class Service < Base
    self.table_name = :report_services

    belongs :demographic   # source client
    belongs :client
  end
end
