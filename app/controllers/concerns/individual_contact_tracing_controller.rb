###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module IndividualContactTracingController
  extend ActiveSupport::Concern

  included do
    before_action :require_health_emergency_contact_tracing!
    before_action :require_can_edit_health_emergency_contact_tracing!
    before_action :set_he_report_access

    def require_health_emergency_contact_tracing!
      return true if health_emergency_contact_tracing?

      not_authorized!
    end

    def health_emergency_contact_tracing?
      health_emergency_contact_tracing.present?
    end

    def health_emergency_contact_tracing
      @health_emergency_contact_tracing ||= GrdaWarehouse::Config.get(:health_emergency_tracing)
    end
    helper_method :health_emergency_contact_tracing

    private def set_case
      @case = Health::Tracing::Case.find(params[:case_id].to_i)
    end

    private def set_client
      @client = @case.client
    end

    private def set_he_report_access
      url = 'warehouse_reports/health/contact_tracing'
      @he_report_access = GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(current_user).exists?
    end
  end
end
