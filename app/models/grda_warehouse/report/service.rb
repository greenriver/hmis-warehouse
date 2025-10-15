###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
