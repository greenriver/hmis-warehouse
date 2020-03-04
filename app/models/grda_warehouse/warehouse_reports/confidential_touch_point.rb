###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class ConfidentialTouchPoint < TouchPoint

    def title
      'Confidential Touch Point Export'
    end

    def url
      warehouse_reports_confidential_touch_point_exports_url(host: ENV.fetch('FQDN'))
    end

  end
end
