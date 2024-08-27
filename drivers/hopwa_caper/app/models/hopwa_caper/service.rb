###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper
  class Service < GrdaWarehouseBase
    self.table_name = 'hopwa_caper_services'

    belongs_to :enrollment, class_name: 'HopwaCaper::Enrollment', foreign_key: [:hud_enrollment_id, :data_source_id, :report_instance_id], primary_key: [:hud_enrollment_id, :data_source_id, :report_instance_id]

    def self.as_report_members
      all.map do |record|
        ::HudReports::UniverseMember.new(
          universe_membership_type: sti_name,
          universe_membership_id: record.id,
        )
      end
    end

    scope :all_hopwa_assistance, -> {
      hopwa_types = [
        HudUtility2024.record_types.invert.fetch('HOPWA Financial Assistance'),
        HudUtility2024.record_types.invert.fetch('HOPWA Service'),
      ]
      where(record_type: hopwa_types)
    }

    scope :hopwa_financial_assistance, -> {
      where(record_type: HudUtility2024.record_types.invert.fetch('HOPWA Financial Assistance'))
    }

    scope :hopwa_service, -> {
      where(record_type: HudUtility2024.record_types.invert.fetch('HOPWA Service'))
    }

    def self.from_hud_record(service:, enrollment:, report:)
      new(
        report_household_id: [service.data_source_id, enrollment.household_id, report.id].join(':'),
        report_instance_id: report.id,
        data_source_id: service.data_source_id,
        hud_enrollment_id: service.enrollment_id,
        hud_services_id: service.services_id,

        date_provided: service.date_provided,
        record_type: service.record_type,
        type_provided: service.type_provided,
        fa_amount: service.fa_amount,
      )
    end
  end
end
