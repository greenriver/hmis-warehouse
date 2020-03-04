###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class ConfidentialTouchPointExportsController < TouchPointExportsController
    include WarehouseReportAuthorization
    before_action :require_can_administer_health!

    def index
      options = { search_scope: touch_point_scope }
      options.merge!(filter_params) if filter_params.present?
      @filter = ::Filters::HealthTouchPointExportsFilter.new(options)
      @reports = report_scope.for_list.
        order(created_at: :desc).
        page(params[:page]).
        per(25)
    end

    def download
      @patients = ::Health::Patient.where(client_id: @client_ids.to_a).
        joins(:careplans).
        index_by(&:client_id)
      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=\"Health TouchPoints-#{@name} #{@start_date&.to_date&.strftime('%F')} to #{@end_date&.to_date&.strftime('%F')}.xlsx\""
        end
      end
    end

    def report_scope
      GrdaWarehouse::WarehouseReports::ConfidentialTouchPoint.for_user(current_user)
    end

    def report_source
      GrdaWarehouse::HmisForm.health_touch_points
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.confidential
    end

    def file_name
      'ConfidentialTouchPoints'
    end

    def reports_location
      warehouse_reports_confidential_touch_point_exports_path
    end
  end
end
