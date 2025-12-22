# frozen_string_literal: true

module HudReports
  class HouseholdContext < GrdaWarehouseBase
    self.table_name = 'hud_report_household_contexts'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :service_history_enrollment, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'

    validates :report_instance_id, presence: true
    validates :service_history_enrollment_id, presence: true, uniqueness: { scope: :report_instance_id }
  end
end
