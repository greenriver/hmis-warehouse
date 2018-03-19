module WarehouseReports
  class ConfidentialTouchPointExportsController < TouchPointExportsController
    before_action :require_can_administer_health!

    def report_source
      GrdaWarehouse::HmisForm.confidential
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.confidential
    end
  end
end
