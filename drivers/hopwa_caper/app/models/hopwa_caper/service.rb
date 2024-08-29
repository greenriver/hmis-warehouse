###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper
  class Service < GrdaWarehouseBase
    self.table_name = 'hopwa_caper_services'

    belongs_to :enrollment, class_name: 'HopwaCaper::Enrollment', primary_key: :enrollment_id

    def self.as_report_members
      all.map do |record|
        ::HudReports::UniverseMember.new(
          universe_membership_type: sti_name,
          universe_membership_id: record.id,
        )
      end
    end

    def self.from_hud_record(service:, enrollment:, report:, client:)
      new(
        report_household_id: [service.data_source_id, enrollment.household_id, report.id].join(':'),
        report_instance_id: report.id,

        warehouse_client_id: client.id,
        enrollment_id: enrollment.id,
        service_id: service.id,
        hud_personal_id: client.personal_id,

        date_provided: service.date_provided,
        record_type: service.record_type,
        type_provided: service.type_provided,
        fa_amount: service.fa_amount,
      )
    end
  end
end
