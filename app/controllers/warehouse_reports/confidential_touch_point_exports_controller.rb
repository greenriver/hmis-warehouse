module WarehouseReports
  class ConfidentialTouchPointExportsController < TouchPointExportsController
    before_action :require_can_administer_health!

    def download
      @patients = Health::Patient.where(client_id: @client_ids.to_a).
        joins(:careplan).
        index_by(&:client_id)
      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Touch Point Exports - #{@name} #{@start} to #{@end}.xlsx"
        end
      end
    end

    def report_source
      GrdaWarehouse::HmisForm.health_touch_points
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.confidential
    end
  end
end
